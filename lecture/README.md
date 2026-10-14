# これは演習用のフォルダです。


## Linuxデモンストレーション
以下のファイル構成・権限を目指します。
権限は `ls -la` で表示される記号表記（例: `-rw-------`）で記載しています。

```ファイル構成
lecture/                                        drwxr-xr-x
├── README.md                                   -rw-r--r--
├── docker-compose.yml                          -rw-r--r--
├── backend/                                     drwxr-xr-x
│   ├── Dockerfile                              -rw-r--r--
│   ├── main.py                                 -rw-r--r--
|   ├── .env                                    -rw-------  ← chmod 600（機密情報のため所有者のみ）
|   ├── .env.example                            -rw-r--r--  ← 共有用テンプレート
│   ├── requirements.txt                        -rw-r--r--
└── frontend/                                    drwxr-xr-x
    ├── Dockerfile                              -rw-r--r--
    ├── index.html                              -rw-r--r--
    ├── package-lock.json                       -rw-r--r--
    ├── package.json                            -rw-r--r--
    ├── tsconfig.json                           -rw-r--r--
    ├── vite.config.ts                          -rw-r--r--
    └── src/                                     drwxr-xr-x
        ├── App.tsx                             -rw-r--r--
        └── main.tsx                            -rw-r--r--
```


## Dockerデモンストレーション
Docker composeを使って開発サーバーを立ち上げられます。
```
cp backend/.env.example backend/.env && chmod 600 backend/.env   # 初回のみ
docker compose up -d --build
```

### 送信すると「通信に失敗しました。」(504) になる場合
Codespaceでは、古い方式のファイアウォール(iptables-legacy)がコンテナ間の通信を捨ててしまうことがあります。
Composeのネットワーク(`br-`で始まる名前)同士の通信を許可するため、Codespace起動後に1回だけ次を実行してください。
```
sudo iptables-legacy -I FORWARD 1 -i br-+ -o br-+ -j ACCEPT
```
- 設定はCodespaceを再起動すると消えます(再起動後にもう一度実行)。
- 元に戻す場合: `sudo iptables-legacy -D FORWARD -i br-+ -o br-+ -j ACCEPT`

以下が開発用サーバーになっています。
http://localhost:8080/