# --- ビルド用ステージ ---
FROM python:3.12-slim AS builder

WORKDIR /app

# 仮想環境を作成
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
# && で順番に実行
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt


# --- 実行用ステージ ---
FROM python:3.12-slim AS runner
WORKDIR /app

# ビルドステージから仮想環境ごとコピー
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# アプリケーションコードを配置
COPY . /app/

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]