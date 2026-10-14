# --- ビルド用ステージ ---
FROM node:22-slim AS builder

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY . .
RUN npm run build

# --- 実行用ステージ ---
# 軽量なnginxイメージでビルド済み静的ファイルを配信する
FROM nginx:alpine AS runner

# viteのビルド成果物(dist)のみをnginxの公開ディレクトリに配置
COPY --from=builder /app/dist /usr/share/nginx/html

# /app/apiをbackendコンテナへリバースプロキシする設定
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 80番ポートで待ち受け(nginxイメージの標準設定)
EXPOSE 80
