#!/bin/bash
# newworld.sh - 旧ワールドをbackups/以下に階層保存して新ワールド生成

set -e

DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="backups/${DATE}"

echo ">> サーバーは停止していますか？ (必須)"
read -p "続行するなら Enter を押してください..."

# バックアップ先ディレクトリを作成
mkdir -p "$BACKUP_DIR"

# world ディレクトリが存在するか確認して移動
if [ -d "world" ] || [ -d "world_nether" ] || [ -d "world_the_end" ]; then
  echo ">> ワールドを ${BACKUP_DIR}/ に移動"
  mv world world_nether world_the_end "$BACKUP_DIR"/ 2>/dev/null || true
else
  echo ">> ワールドフォルダが見つかりません"
fi

echo ">> 新しいワールドはサーバー起動時に自動生成されます"
echo ">> 完了！ バックアップは ${BACKUP_DIR}/ に保存されました"

