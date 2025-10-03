# Minecraft Server Tools

PaperMC サーバーを簡単に構築・管理するためのスクリプト集。

## スクリプト一覧
- `setup.sh`  
  サーバー初期構築（PaperMC ダウンロード + systemd 登録）

- `update.sh`  
  PaperMC バージョン更新（古い jar/プラグイン退避）

- `plugins_update.sh`  
  プラグイン一括更新（EssentialsX, LuckPerms, ViaVersion, Multiverse, etc.）

- `newworld.sh`  
  旧ワールド退避 + 新ワールド生成

## 必要パッケージ
- bash
- curl
- jq
- Java 21 (temurin-21-jre)

## 使用方法
```bash
./setup.sh <PaperMCダウンロードURL>
./update.sh <PaperMCダウンロードURL>
./plugins_update.sh
./newworld.sh

