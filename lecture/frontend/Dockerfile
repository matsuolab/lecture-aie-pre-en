# --- Build stage ---
FROM node:22-slim AS builder

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY . .
RUN npm run build

# --- Runtime stage ---
# Serve the built static files using a lightweight nginx image
FROM nginx:alpine AS runner

# Copy only the vite build output (dist) into the directory served by nginx
COPY --from=builder /app/dist /usr/share/nginx/html

# Configuration to reverse-proxy /app/api to the backend container
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Listen on port 80 (the default for the nginx image)
EXPOSE 80
