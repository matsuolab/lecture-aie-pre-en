# 次回の準備課題

次回は、Webページからの応答を確認し、その結果と日時をレポートにまとめます。この処理を、自分のRepositoryで動かします。その材料になる二つのファイルを、自分のCodespaceに用意しておいてください。目安は10分ほどです。提出はありません。

## 用意するもの

`pre_day2`というフォルダーの中に、次の二つを作ります。

- `pre_day2/template.md` — レポートの文章の原本
- `pre_day2/generate.sh` — 原本からレポートを作る処理

中身は、このページの下にあります。読んで動かすのは次回です。今回は用意するだけで構いません。

## やること

1. 今日使っていたCodespaceを開きます。タブが残っていれば、それに戻ります。閉じていた場合は、GitHubで自分のRepositoryのページを開き、今日と同じように`Code`から`Codespaces`を選ぶと、今日作ったCodespaceが一覧に出るので、それを押します。新しく作らないでください。
2. ファイル一覧で、新しいファイル`pre_day2/template.md`を作ります。作り方は次の節にあります。
3. 下の「template.md」の枠の中身をコピーして貼り付け、今日と同じように保存します。
4. `pre_day2/generate.sh`も、同じ手順で作って保存します。
5. 二つのファイルを開いて、このページの枠と同じ中身になっているか見比べます。

今回はbranchを作らず、masterのまま進めて構いません。記録は次回に行います。

## 新しいファイルの作り方（今日の実習で扱っていない操作）

1. ファイル一覧の一番上にある、自分のRepository名の行（大文字で表示されています）を右クリックします。
2. 出てきたメニューの`New File...`（新しいファイル）を選びます。名前の入力欄が出ます。
3. `pre_day2/template.md`と入力して、Enterキーを押します。`pre_day2`フォルダーと、その中のファイルが同時にでき、空の編集画面が開きます。

表示が違う場合は、ファイル一覧の中で「新しいファイル」にあたる項目を探してください。また、ファイルが並んでいる下の空白を右クリックしても、同じメニューが出ます。Codespaceの編集画面は、VS Codeというエディターです。公式の画面案内: [User Interface — Explorer（VS Code Docs）](https://code.visualstudio.com/docs/editing/getting-started/userinterface#_explorer-view)

## 貼り付ける中身

枠の中身だけを貼り付けます。ファイル名や、枠を囲む記号は入れません。ターミナルには貼り付けないでください。今回は実行しません。

### template.md

```markdown
# Webページの確認レポート

対象: https://example.com/
確認日時（UTC）: {{CHECKED_AT}}
応答コード: {{HTTP_STATUS}}

このレポートは、原本と確認結果をもとに生成します。
```

### generate.sh

```sh
#!/bin/sh

# このファイルは、Webページの確認結果からレポートを作るスクリプトです。
# 1行目の #! は、この中身を sh というプログラムで実行してほしい、という指定です。
# # から行末までは、実行されない説明書きです。

# 途中でエラーが起きたら、その時点で止めます（-e）。
# 中身が決まっていない値を使おうとしたときも止めます（-u）。
set -eu

# このスクリプトが置かれているフォルダーへ移動します。
# $0 はこのファイル自身の場所、dirname はそこからフォルダー名だけを取り出す命令です。
# どこから実行しても、となりにある template.md を同じように読めるようにしています。
cd "$(dirname "$0")"

# case で、実行時に後ろへ付けた文字の個数ごとに処理を分けます。
# $# は、後ろへ付けた文字の個数です。
case "$#" in
  # 0 は、後ろに何も付けずに実行した場合です。
  0)
    # [1] Webページへアクセスし、応答コードを http_status に入れます。
    #     失敗はエラーとして扱い、30秒で打ち切り、本文は保存しません。
    http_status=$(curl --fail --silent --show-error --location --max-time 30 \
      --output /dev/null --write-out '%{http_code}' https://example.com/)

    # [2] 確認した日時を、世界標準時で checked_at に入れます。
    checked_at=$(date -u '+%Y-%m-%d %H:%M:%S UTC')

    # [3] template.md の二つの印を上の値に置き換え、report.md に書き出します。
    #     区切りに | を使うのは、値に / が入っても壊れないようにするためです。
    sed -e "s|{{CHECKED_AT}}|$checked_at|g" \
        -e "s|{{HTTP_STATUS}}|$http_status|g" template.md > report.md

    printf '%s\n' 'report.md を生成しました。'
    # ;; でこの場合の処理を終えます。
    ;;

  # 1 は、後ろに文字を一つ付けて実行した場合です。
  1)
    # $1 は、実行時に後ろへ付けた一つ目の文字のことです。
    if [ "$1" != "setup-actions" ]; then
      printf '%s\n' '使い方: ./generate.sh または ./generate.sh setup-actions' >&2
      exit 2
    fi
    # 自動実行の設定を置くフォルダーを作ります。すでにある場合はそのまま使います。
    mkdir -p ../.github/workflows
    # 次の行から WORKFLOW と書かれた行の手前までを、そのままファイルへ書き出します。
    cat > ../.github/workflows/update-report.yml <<'WORKFLOW'
name: Update report

on:
  push:
    branches: [master]
    paths:
      - pre_day2/template.md
      - pre_day2/generate.sh
      - .github/workflows/update-report.yml
  workflow_dispatch:

permissions:
  contents: write

jobs:
  update-report:
    runs-on: ubuntu-latest
    steps:
      - name: Check out the repository
        uses: actions/checkout@v7

      - name: Check required tools
        run: |
          command -v sh
          command -v sed
          command -v date
          command -v curl

      - name: Generate the report
        run: |
          chmod +x pre_day2/generate.sh
          ./pre_day2/generate.sh

      - name: Commit the changed report
        run: |
          if [ -z "$(git status --porcelain -- pre_day2/report.md)" ]; then
            echo "report.md に変更はありません。"
            exit 0
          fi
          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git add pre_day2/report.md
          git commit -m "chore: update report"
          git push
WORKFLOW
    # 書き出せたことを画面に伝えます。
    printf '%s\n' '.github/workflows/update-report.yml を作成しました。'
    ;;

  # * は、ここまでのどちらにも当てはまらない場合です。
  *)
    printf '%s\n' '使い方: ./generate.sh または ./generate.sh setup-actions' >&2
    exit 2
    ;;
# esac で case 全体を終えます。
esac
```

## できた状態

- ファイル一覧の`pre_day2`の中に二つのファイルがあり、開くとこのページの枠と同じ中身です。
- 今日の実習で、変更したファイルの名前を確かめた操作をすると、`pre_day2/`が表示されます。新しく作ったファイルなので、今日とは違う見出しの下に出ますが、`pre_day2/`が見えていれば大丈夫です。保存はしたが、まだ記録していない状態です。記録は次回に行うので、今回はここまでで完了です。
- 次回はこのCodespaceから始めます。Codespaceは消さずに残してください。もしCodespaceが消えていた場合は、今日と同じ手順で新しく作り、二つのファイルもこのページの手順でもう一度作ります。
