#!/bin/bash
set -e

INSTALL_DIR="$HOME/minecraft"
SERVICE_NAME="minecraft"

if [ -z "$1" ]; then
  echo "使い方: $0 <PaperMCダウンロードURL>"
  echo "PaperMC ダウンロードページ: https://papermc.io/downloads/paper"
  exit 1
fi

URL="$1"
FILENAME=$(basename "$URL")

echo ">> 必要なパッケージをインストール (Java 21, curl, jq)"
sudo apt update
sudo apt install -y curl jq temurin-21-jre

echo ">> Minecraft ディレクトリ作成: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo ">> PaperMC ダウンロード: $URL"
curl -L -o "$FILENAME" "$URL"
ln -s "$FILENAME" paper.jar

echo ">> EULA 同意"
echo "eula=true" > eula.txt

echo ">> systemd ユニット作成"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Minecraft PaperMC Server
After=network.target

[Service]
WorkingDirectory=${INSTALL_DIR}
User=$USER
Restart=on-failure
RestartSec=10
ExecStart=/usr/bin/java -Xmx6G -Xms2G -jar paper.jar nogui
ExecStop=/bin/kill -SIGTERM \$MAINPID
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable ${SERVICE_NAME}

echo "========================================"
echo "セットアップ完了！"
echo "起動:   sudo systemctl start ${SERVICE_NAME}"
echo "停止:   sudo systemctl stop ${SERVICE_NAME}"
echo "再起動: sudo systemctl restart ${SERVICE_NAME}"
echo "状態:   systemctl status ${SERVICE_NAME}"
echo "ログ:   sudo journalctl -xefu ${SERVICE_NAME}"
echo "========================================"

