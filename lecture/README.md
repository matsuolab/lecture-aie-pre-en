# Folder for the Exercises


## Linux Demonstration
Aim for the following file structure and permissions.
Permissions are shown in the symbolic notation displayed by `ls -la` (for example, `-rw-------`).

```file-structure
lecture/                                        drwxr-xr-x
├── README.md                                   -rw-r--r--
├── docker-compose.yml                          -rw-r--r--
├── backend/                                     drwxr-xr-x
│   ├── Dockerfile                              -rw-r--r--
│   ├── main.py                                 -rw-r--r--
|   ├── .env                                    -rw-------  ← chmod 600 (owner only, because it contains sensitive information)
|   ├── .env.example                            -rw-r--r--  ← template for sharing
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


## Docker Demonstration
You can start the development server using Docker compose.
```
cp backend/.env.example backend/.env && chmod 600 backend/.env   # First time only
docker compose up -d --build
```

### If Sending a Message Produces a 504 Error: "Communication failed".
In Codespace, the legacy firewall (iptables-legacy) may drop traffic between containers.
To allow traffic between Compose networks (whose names start with `br-`), run the following once after starting Codespace.
```
sudo iptables-legacy -I FORWARD 1 -i br-+ -o br-+ -j ACCEPT
```
- This setting is lost when you restart Codespace (run the command again after restarting).
- To undo it: `sudo iptables-legacy -D FORWARD -i br-+ -o br-+ -j ACCEPT`

The development server is available at the following URL.
http://localhost:8080/