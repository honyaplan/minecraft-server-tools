#!/bin/bash
# plugins_update.sh - Minecraft PaperMC 用プラグイン更新スクリプト
# バックアップを残しつつ、plugins_list.txt に基づいて最新版をダウンロードする

set -e

INSTALL_DIR="$HOME/minecraft"
PLUGINS_DIR="$INSTALL_DIR/plugins"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIST_FILE="$SCRIPT_DIR/plugins_list.txt"

DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$INSTALL_DIR/backups/plugins_$DATE"

mkdir -p "$BACKUP_DIR"
mv "$PLUGINS_DIR" "$BACKUP_DIR"/ 2>/dev/null || true
mkdir -p "$PLUGINS_DIR"

# 実行時のリストもバックアップに保存
cp "$LIST_FILE" "$BACKUP_DIR/plugins_list.txt"

# オプション処理
ENABLE_ESSENTIALS_ADDONS=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --enable-essentialsx-addons)
      ENABLE_ESSENTIALS_ADDONS=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# ログ関数
log()  { echo -e "\033[0;36m[INFO]\033[0m $1"; }
warn() { echo -e "\033[0;33m[WARN]\033[0m $1"; }
err()  { echo -e "\033[0;31m[ERROR]\033[0m $1"; }

# ダウンロード関数
download() {
  local url="$1"
  local out="$2"
  if [ -z "$url" ] || [ "$url" = "null" ]; then
    err "$out no URL"
    echo "$out" >> "$BACKUP_DIR/FAILED_PLUGINS.txt"
    return 1
  fi
  if curl -L --fail -o "$PLUGINS_DIR/$out" "$url"; then
    log "$out downloaded"
  else
    err "$out failed"
    echo "$out" >> "$BACKUP_DIR/FAILED_PLUGINS.txt"
  fi
}

# GitHub Releases API（null安全）
get_github_release() {
  local repo="$1"
  local pattern="$2"
  curl -s "https://api.github.com/repos/$repo/releases/latest" \
    | jq -r --arg PATTERN "$pattern" '.assets[]? | select(.name|test($PATTERN)) | .browser_download_url' \
    | head -n1
}

# Modrinth API（ローダーフィルタ & null安全）
# 第3引数に "bukkit|paper|spigot" などのローダー正規表現を渡せます
get_modrinth_release() {
  local project="$1"
  local pattern="$2"
  local loader_re="${3:-}"
  if [ -n "$loader_re" ]; then
    curl -s "https://api.modrinth.com/v2/project/$project/version" \
      | jq -r --arg PATTERN "$pattern" --arg LOADER_RE "$loader_re" '
        [.[] | select(.version_type=="release")
               | select((.loaders // []) | join(",") | test($LOADER_RE; "i"))]
        | .[0]?.files[]?
        | select(.filename | test($PATTERN; "i"))
        | .url
      ' | head -n1
  else
    curl -s "https://api.modrinth.com/v2/project/$project/version" \
      | jq -r --arg PATTERN "$pattern" '
        [.[] | select(.version_type=="release")] | .[0]?.files[]?
        | select(.filename | test($PATTERN; "i"))
        | .url
      ' | head -n1
  fi
}

# Hangar API（null安全）
get_hangar_release() {
  local slug="$1"
  curl -s "https://hangar.papermc.io/api/v1/projects/$slug/versions" \
    | jq -r '.result[0]?.downloads?.PAPER?.downloadUrl // empty'
}

log "Updating plugins from $LIST_FILE..."

while read -r JAR; do
  case "$JAR" in
    # --- 安定取得 ---
    Chunky.jar) URL=$(get_hangar_release "Chunky") ;;

    # BlueMap は Modrinth の bukkit/paper/spigot を優先、無ければ GitHub にフォールバック
    BlueMap.jar)
      URL=""
      URL=$(get_modrinth_release "bluemap" ".*\\.jar$" "bukkit|paper|spigot") || true
      if [ -z "$URL" ]; then
        URL=$(get_github_release "BlueMap-Minecraft/BlueMap" ".*spigot.*\\.jar$")
      fi
      ;;

    Geyser-Spigot.jar) URL="https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot" ;;
    DiscordSRV.jar) URL=$(get_github_release "DiscordSRV/DiscordSRV" ".*\\.jar$") ;;
    Vault.jar) URL="https://github.com/MilkBowl/Vault/releases/latest/download/Vault.jar" ;;

    # Modrinth もローダーフィルタで forge 等を除外
    WorldEdit.jar) URL=$(get_modrinth_release "worldedit" ".*\\.jar$" "bukkit|paper|spigot") ;;
    TerraformGenerator.jar) URL=$(get_modrinth_release "terraformgenerator" ".*\\.jar$" "bukkit|paper|spigot") ;;

    Plan.jar) URL=$(get_github_release "plan-player-analytics/Plan" "Plan.*\\.jar$") ;;
    LuckPerms-Bukkit.jar) URL=$(curl -s "https://metadata.luckperms.net/data/all" | jq -r '.downloads.bukkit // empty') ;;
    EssentialsXSpawn.jar) URL=$(get_github_release "EssentialsX/Essentials" "Spawn.*\\.jar$") ;;
    Floodgate.jar) URL="https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot" ;;
    GSit.jar) URL=$(get_github_release "Gecolay/GSit" ".*\\.jar$") ;;
    EssentialsX.jar) URL=$(get_github_release "EssentialsX/Essentials" "^EssentialsX-[0-9].*\\.jar$") ;;
    EssentialsXGeoIP.jar) warn "$JAR is deprecated (no longer distributed)"; URL="" ;;
    ViaVersion.jar) URL=$(get_github_release "ViaVersion/ViaVersion" "ViaVersion.*\\.jar$") ;;
    ViaBackwards.jar) URL=$(get_github_release "ViaVersion/ViaBackwards" "ViaBackwards.*\\.jar$") ;;
    Multiverse-Core.jar) URL=$(get_hangar_release "Multiverse-Core") ;;
    Multiverse-Inventories.jar) URL=$(get_hangar_release "Multiverse-Inventories") ;;
    Multiverse-Portals.jar) URL=$(get_hangar_release "Multiverse-Portals") ;;
    Multiverse-NetherPortals.jar) URL=$(get_hangar_release "Multiverse-NetherPortals") ;;
    ServerRestorer.jar) URL=$(get_hangar_release "ServerRestorer") ;;

    # EssentialsX addons（オプション）
    EssentialsXAntiBuild.jar|EssentialsXChat.jar|EssentialsXProtect.jar)
      if [ "$ENABLE_ESSENTIALS_ADDONS" = true ]; then
        case "$JAR" in
          EssentialsXAntiBuild.jar) URL=$(get_github_release "EssentialsX/Essentials" "AntiBuild.*\\.jar$") ;;
          EssentialsXChat.jar)      URL=$(get_github_release "EssentialsX/Essentials" "Chat.*\\.jar$") ;;
          EssentialsXProtect.jar)   URL=$(get_github_release "EssentialsX/Essentials" "Protect.*\\.jar$") ;;
        esac
      else
        warn "Skipping $JAR (EssentialsX addon disabled)"
        URL=""
      fi
      ;;

    # --- 未対応 ---
    *)
      warn "No URL mapping for $JAR, skipping"
      URL=""
      ;;
  esac

  [ -n "$JAR" ] && [ -n "$URL" ] && download "$URL" "$JAR"
done < "$LIST_FILE"

if [ -f "$BACKUP_DIR/FAILED_PLUGINS.txt" ]; then
  log "Plugins update finished. Failed list: $BACKUP_DIR/FAILED_PLUGINS.txt"
else
  log "Plugins update finished. All plugins downloaded successfully 🎉"
fi

