#!/bin/sh

# This program prepares for pre-Day3 (the Docker practice section).
# Run it once before the lecture to avoid waiting during class.
# It is stored at pre_day3/prepare.sh in the repository. To run it, use
#   chmod +x pre_day3/prepare.sh
#   ./pre_day3/prepare.sh
# just these two commands (the same operations you learned in pre-Day2).

# Stop immediately if an error occurs (-e).
# Also stop if an unset value is used (-u).
set -eu

# [1] Store the versions of the image and model to download in variables.
#     Students should not change this section.
IMAGE='ghcr.io/ggml-org/llama.cpp:server-v0.5.0'
MODEL_DIR='/workspaces/models'
MODEL_FILE='gemma-4-E2B-it-UD-Q4_K_XL.gguf'
MODEL_URL='https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/0314792d7f1f7e229411f620751375812bb9faf2/gemma-4-E2B-it-UD-Q4_K_XL.gguf'
MODEL_SHA256='b52f438017efaec5debf1c0d8be690571e212a07c312f1102bbce927258cfc32'
LLM_CHAT_DIR='/workspaces/llm-chat'
# Disk space guideline: about 3.5GB to download. Allow 4GB (4*1024*1024 KB) for some headroom.
REQUIRED_FREE_KB=4194304

# [2] Check whether the Docker daemon is reachable.
#     If it is not, stop here and explain what to do next.
check_docker() {
  if ! docker version >/dev/null 2>&1; then
    printf '%s\n' 'Error: Docker is unavailable.' >&2
    printf '%s\n' 'Docker has not finished starting in this Codespace, or this environment cannot use Docker.' >&2
    printf '%s\n' 'Wait a few dozen seconds, then run ./pre_day3/prepare.sh again.' >&2
    exit 1
  fi
}

# [3] Check the free space in /workspaces.
#     If there is not enough space, stop here and explain what to do next.
check_disk_space() {
  free_kb=$(df -Pk "$MODEL_DIR_PARENT" | awk 'NR==2 {print $4}')
  if [ "$free_kb" -lt "$REQUIRED_FREE_KB" ]; then
    printf '%s\n' 'Error: Not enough free space in /workspaces.' >&2
    printf '%s\n' 'At least about 4GB of free space is needed (image: about 308MB; model: about 3.2GB).' >&2
    printf '%s\n' 'Delete unused Codespaces or unnecessary files, then' >&2
    printf '%s\n' 'run ./pre_day3/prepare.sh again.' >&2
    exit 1
  fi
}

# [4] Download the llama.cpp image. Skip the download if it is already available.
pull_image() {
  if docker image inspect "$IMAGE" >/dev/null 2>&1; then
    printf '%s\n' "The image is already available ($IMAGE). Skipping the download."
    return 0
  fi
  printf '%s\n' "Downloading the image ($IMAGE). This may take several minutes."
  if ! docker pull "$IMAGE"; then
    printf '%s\n' 'Error: Failed to download the image.' >&2
    printf '%s\n' 'Check your network connection, then run ./pre_day3/prepare.sh again.' >&2
    exit 1
  fi
}

# [5] Check that the file has the expected SHA-256. Return 0 for a match, or 1 otherwise.
matches_sha256() {
  target_file="$1"
  [ -f "$target_file" ] || return 1
  actual=$(sha256sum "$target_file" | awk '{print $1}')
  [ "$actual" = "$MODEL_SHA256" ]
}

# [6] Download the model file.
#     Skip the download if it is already verified; delete and retry any interrupted download.
fetch_model() {
  mkdir -p "$MODEL_DIR"
  model_path="$MODEL_DIR/$MODEL_FILE"
  tmp_path="$model_path.download"

  if matches_sha256 "$model_path"; then
    printf '%s\n' "The model is already available and verified ($model_path). Skipping the download."
    return 0
  fi

  # Delete any file left over from a previously interrupted download.
  rm -f "$tmp_path"

  printf '%s\n' 'Downloading the model. This may take about a minute.'
  if ! curl --fail --silent --show-error --location --output "$tmp_path" "$MODEL_URL"; then
    rm -f "$tmp_path"
    printf '%s\n' 'Error: Failed to download the model.' >&2
    printf '%s\n' 'Check your network connection, then run ./pre_day3/prepare.sh again.' >&2
    exit 1
  fi

  if ! matches_sha256 "$tmp_path"; then
    rm -f "$tmp_path"
    printf '%s\n' 'Error: The downloaded model is invalid (SHA-256 mismatch).' >&2
    printf '%s\n' 'The connection may have been interrupted. Run ./pre_day3/prepare.sh again.' >&2
    exit 1
  fi

  mv "$tmp_path" "$model_path"
  printf '%s\n' 'The model has been downloaded and verified.'
}

# [7] Place the Dockerfile for the AI at /workspaces/llm-chat/Dockerfile.
#     Its contents are embedded in this program (the same Dockerfile as on the distribution page).
place_llm_chat_dockerfile() {
  mkdir -p "$LLM_CHAT_DIR"
  cat > "$LLM_CHAT_DIR/Dockerfile" <<'DOCKERFILE'
# [1] Base image: an image containing the llama.cpp server.
#     Pin the version (server-v0.5.0). Using latest could change the contents on each rebuild.
FROM ghcr.io/ggml-org/llama.cpp:server-v0.5.0

# [2] Setting (environment variable): the location of the model to load.
#     Keep the model file outside the image, and pass it into /models using docker run -v (bind mount).
ENV LLAMA_ARG_MODEL=/models/gemma-4-E2B-it-UD-Q4_K_XL.gguf

# [3] Setting: the listening port. Listen on 0.0.0.0 port 8080 to allow connections from outside the container.
ENV LLAMA_ARG_HOST=0.0.0.0
ENV LLAMA_ARG_PORT=8080

# [4] Settings: disable reasoning. Set how much conversation the model can remember (ctx-size).
#     Set the maximum length of each response (n-predict).
ENV LLAMA_ARG_REASONING=off
ENV LLAMA_ARG_CTX_SIZE=4096
ENV LLAMA_ARG_N_PREDICT=256

# [5] Setting: the initial instruction to the AI (system prompt). Change this and rerun docker build
#     to change how the AI responds. Only edit the text inside the "" on this line.
#     Keep the nesting of quotation marks intact (single quotes outside, double quotes inside).
ENV LLAMA_ARG_UI_CONFIG='{"systemMessage":"You are a helpful assistant. Answer briefly."}'
DOCKERFILE
  printf '%s\n' "Placed $LLM_CHAT_DIR/Dockerfile."
}

# Execution starts here (call the functions [2]-[7] in this order).
MODEL_DIR_PARENT=$(dirname "$MODEL_DIR")
check_docker
check_disk_space
pull_image
fetch_model
place_llm_chat_dockerfile

printf '%s\n' 'Preparation complete'
