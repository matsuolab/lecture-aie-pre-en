#!/bin/sh

# このファイルは、Day3（Docker演習パート）の準備用プログラムです。
# 講義の前に一度実行しておくことで、講義中に待たずに済むようにします。
# 保存場所は Repository の中の pre_day3/prepare.sh、実行は
#   chmod +x pre_day3/prepare.sh
#   ./pre_day3/prepare.sh
# の2つだけです（Day2で覚えた操作と同じです）。

# 途中でエラーが起きたら、その時点で止めます（-e）。
# 中身が決まっていない値を使おうとしたときも止めます（-u）。
set -eu

# [1] 取得するimageとモデルの版を、変数にまとめておきます。
#     ここは受講者が書き換える場所ではありません。
IMAGE='ghcr.io/ggml-org/llama.cpp:server-v0.5.0'
MODEL_DIR='/workspaces/models'
MODEL_FILE='gemma-4-E2B-it-UD-Q4_K_XL.gguf'
MODEL_URL='https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/0314792d7f1f7e229411f620751375812bb9faf2/gemma-4-E2B-it-UD-Q4_K_XL.gguf'
MODEL_SHA256='b52f438017efaec5debf1c0d8be690571e212a07c312f1102bbce927258cfc32'
LLM_CHAT_DIR='/workspaces/llm-chat'
# 空き容量の目安：取得量は約3.5GB。余裕を見て4GB（4×1024×1024 KB）を基準にします。
REQUIRED_FREE_KB=4194304

# [2] Dockerのserverにつながるか確認します。
#     つながらなければ、ここで止めて次の行動を伝えます。
check_docker() {
  if ! docker version >/dev/null 2>&1; then
    printf '%s\n' 'エラー：Dockerが使えません。' >&2
    printf '%s\n' 'このCodespaceでDockerの起動が終わっていないか、Dockerが使えない環境です。' >&2
    printf '%s\n' '数十秒待ってからもう一度 ./pre_day3/prepare.sh を実行してください。' >&2
    exit 1
  fi
}

# [3] /workspaces の空き容量を確認します。
#     足りなければ、ここで止めて次の行動を伝えます。
check_disk_space() {
  free_kb=$(df -Pk "$MODEL_DIR_PARENT" | awk 'NR==2 {print $4}')
  if [ "$free_kb" -lt "$REQUIRED_FREE_KB" ]; then
    printf '%s\n' 'エラー：/workspaces の空き容量が足りません。' >&2
    printf '%s\n' '約4GB以上の空きが必要です（image約308MB、モデル約3.2GB）。' >&2
    printf '%s\n' '使っていないCodespaceを削除するか、不要なファイルを消してから、' >&2
    printf '%s\n' 'もう一度 ./pre_day3/prepare.sh を実行してください。' >&2
    exit 1
  fi
}

# [4] llama.cppのimageを取得します。すでに取得済みなら取り直しません。
pull_image() {
  if docker image inspect "$IMAGE" >/dev/null 2>&1; then
    printf '%s\n' "imageは取得済みです（$IMAGE）。取得をとばします。"
    return 0
  fi
  printf '%s\n' "imageを取得します（$IMAGE）。数分かかることがあります。"
  if ! docker pull "$IMAGE"; then
    printf '%s\n' 'エラー：imageの取得に失敗しました。' >&2
    printf '%s\n' 'ネットワークの状態を確認し、もう一度 ./pre_day3/prepare.sh を実行してください。' >&2
    exit 1
  fi
}

# [5] ファイルのSHA-256が期待どおりか確認します。一致すれば0、しなければ1を返します。
matches_sha256() {
  target_file="$1"
  [ -f "$target_file" ] || return 1
  actual=$(sha256sum "$target_file" | awk '{print $1}')
  [ "$actual" = "$MODEL_SHA256" ]
}

# [6] モデルファイルを取得します。
#     一致済みなら取り直さず、途中で止まったファイルは消して取り直します。
fetch_model() {
  mkdir -p "$MODEL_DIR"
  model_path="$MODEL_DIR/$MODEL_FILE"
  tmp_path="$model_path.download"

  if matches_sha256 "$model_path"; then
    printf '%s\n' "モデルは取得済みで内容も一致しています（$model_path）。取得をとばします。"
    return 0
  fi

  # 前回途中で止まったファイルが残っていたら消します。
  rm -f "$tmp_path"

  printf '%s\n' 'モデルを取得します。1分程度かかることがあります。'
  if ! curl --fail --silent --show-error --location --output "$tmp_path" "$MODEL_URL"; then
    rm -f "$tmp_path"
    printf '%s\n' 'エラー：モデルの取得に失敗しました。' >&2
    printf '%s\n' 'ネットワークの状態を確認し、もう一度 ./pre_day3/prepare.sh を実行してください。' >&2
    exit 1
  fi

  if ! matches_sha256 "$tmp_path"; then
    rm -f "$tmp_path"
    printf '%s\n' 'エラー：取得したモデルの内容が正しくありません（SHA-256が一致しません）。' >&2
    printf '%s\n' '途中で通信が切れた可能性があります。もう一度 ./pre_day3/prepare.sh を実行してください。' >&2
    exit 1
  fi

  mv "$tmp_path" "$model_path"
  printf '%s\n' 'モデルの取得と内容の確認が終わりました。'
}

# [7] AI用のDockerfileを /workspaces/llm-chat/Dockerfile に配置します。
#     中身はこのプログラムの中に持っています（配布ページのDockerfileと同じ内容です）。
place_llm_chat_dockerfile() {
  mkdir -p "$LLM_CHAT_DIR"
  cat > "$LLM_CHAT_DIR/Dockerfile" <<'DOCKERFILE'
# [1] 土台（base image）：llama.cpp のサーバーが入ったimage。
#     版（server-v0.5.0）を固定する。latestを使うと、作り直すたびに中身が変わりうる。
FROM ghcr.io/ggml-org/llama.cpp:server-v0.5.0

# [2] 設定（environment variable）：読み込むモデルの場所。
#     モデルのファイルはimageに入れず、docker run の -v（bind mount）で外から /models に渡す。
ENV LLAMA_ARG_MODEL=/models/gemma-4-E2B-it-UD-Q4_K_XL.gguf

# [3] 設定：受付の窓口（port）。containerの外からつなげるよう 0.0.0.0 の 8080 番で待つ。
ENV LLAMA_ARG_HOST=0.0.0.0
ENV LLAMA_ARG_PORT=8080

# [4] 設定：考える動作（reasoning）を切る。会話を覚えておける長さ（ctx-size）。
#     一度に答える長さの上限（n-predict）。
ENV LLAMA_ARG_REASONING=off
ENV LLAMA_ARG_CTX_SIZE=4096
ENV LLAMA_ARG_N_PREDICT=256

# [5] 設定：AIへの最初の指示（system prompt）。ここを書き換えて docker build をやり直すと、
#     AIの答え方が変わる。書き換えるのはこの行の "" の中の文だけでよい。
#     引用符の入れ子（外側は'、内側は"）を崩さないこと。
ENV LLAMA_ARG_UI_CONFIG='{"systemMessage":"あなたは親切なアシスタントです。短く答えてください。"}'
DOCKERFILE
  printf '%s\n' "$LLM_CHAT_DIR/Dockerfile を配置しました。"
}

# ここから実行順です（[2]〜[7]の関数を、この順で呼び出します）。
MODEL_DIR_PARENT=$(dirname "$MODEL_DIR")
check_docker
check_disk_space
pull_image
fetch_model
place_llm_chat_dockerfile

printf '%s\n' '準備ができました'
