#!/bin/bash
# update.sh - PaperMC サーバー更新用スクリプト
# (旧jar + plugins退避 + エラー時リンク案内 + jar一覧のみ)

set -e

INSTALL_DIR="$HOME/minecraft"
cd "$INSTALL_DIR"

if [ -z "$1" ]; then
  echo "使い方: $0 <PaperMCダウンロードURL>"
  echo "PaperMC ダウンロードページ: https://papermc.io/downloads/paper"
  exit 1
fi

URL="$1"
FILENAME=$(basename "$URL")

DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$INSTALL_DIR/backups/update_${DATE}"

echo ">> サーバーは停止していますか？ (必須)"
read -p "続行するなら Enter を押してください..."

# バックアップ先ディレクトリ作成
mkdir -p "$BACKUP_DIR"

# 既存の jar を退避
if [ -L "paper.jar" ]; then
  TARGET=$(readlink paper.jar)
  echo ">> 旧バージョン ($TARGET) を $BACKUP_DIR に移動"
  mv "$TARGET" "$BACKUP_DIR"/ 2>/dev/null || true
fi

# plugins を退避して .jar 一覧を保存
if [ -d "plugins" ]; then
  echo ">> plugins ディレクトリを $BACKUP_DIR に移動"
  mv plugins "$BACKUP_DIR"/

  echo ">> プラグイン一覧 (.jar のみ) を保存 (${BACKUP_DIR}/plugins_list.txt)"
  find "$BACKUP_DIR/plugins" -maxdepth 1 -type f -name "*.jar" -printf "%f\n" > "${BACKUP_DIR}/plugins_list.txt"
fi

echo ">> 新しい plugins ディレクトリを作成"
mkdir -p plugins

# 新しい PaperMC をダウンロード
echo ">> $URL からダウンロード中..."
if ! curl -L -o "$FILENAME" "$URL"; then
  echo "エラー: ダウンロードに失敗しました。"
  echo "PaperMC のダウンロードページはこちら → https://papermc.io/downloads/paper"
  exit 1
fi

if [ ! -f "$FILENAME" ]; then
  echo "エラー: $FILENAME が見つかりません"
  echo "PaperMC のダウンロードページはこちら → https://papermc.io/downloads/paper"
  exit 1
fi

# シンボリックリンク更新
echo ">> 既存の paper.jar を削除"
rm -f paper.jar

echo ">> 新しいバージョン ($FILENAME) にリンクを張り替え"
ln -s "$FILENAME" paper.jar

echo ">> 更新完了！ 現在のリンク:"
ls -l paper.jar
echo ">> バックアップとプラグイン一覧は $BACKUP_DIR に保存されました"

