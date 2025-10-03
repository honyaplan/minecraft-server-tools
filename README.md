# Minecraft Server Tools

PaperMC サーバー運用を補助するためのスクリプト群です。
ワールドバックアップ、サーバー更新、プラグイン更新などを自動化します。

---

## 📂 構成

* `setup.sh`
  初回セットアップ用スクリプト。PaperMC サーバーを `$HOME/minecraft` に展開し、
  systemd サービスを作成して自動起動できるようにします。

* `update.sh`
  PaperMC を最新バージョンに更新します。旧バージョンとプラグインは
  `backups/update_YYYYMMDD-HHMMSS/` に退避されます。

* `newworld.sh`
  既存ワールドを `backups/` 以下に退避し、新しいワールドを生成します。

* `plugins_update.sh`
  `plugins_list.txt` に基づいて各種プラグインを自動ダウンロードします。
  ダウンロード失敗時は `FAILED_PLUGINS.txt` に記録されます。

* `plugins_list.txt`
  使用するプラグインの一覧（`.jar` ファイル名のみ）。

---

## 🚀 使い方

### 初回セットアップ

```bash
./setup.sh <PaperMCダウンロードURL>
```

例:

```bash
./setup.sh https://api.papermc.io/v2/projects/paper/versions/1.21.1/builds/150/downloads/paper-1.21.1-150.jar
```

セットアップ後は systemd サービスで管理できます:

```bash
sudo systemctl start minecraft
sudo systemctl status minecraft
sudo journalctl -xefu minecraft
```

---

### サーバー更新

```bash
./update.sh <PaperMCダウンロードURL>
```

古い `paper.jar` と `plugins/` はバックアップされます。
最新 PaperMC のダウンロードは [こちら](https://papermc.io/downloads/paper)。

---

### ワールド更新

```bash
./newworld.sh
```

現在のワールド (`world/ world_nether/ world_the_end/`) が退避され、
次回起動時に新しいワールドが自動生成されます。

---

### プラグイン更新

```bash
./plugins_update.sh [オプション]
```

* `plugins_list.txt` に記載されたプラグインを最新化
* 成功: `plugins/` に配置
* 失敗: `backups/plugins_YYYYMMDD-HHMMSS/FAILED_PLUGINS.txt` に記録

#### オプション

* `--enable-essentialsx-addons`
  EssentialsX の追加モジュール（AntiBuild / Chat / Protect）を含めて更新します。
  省略時は EssentialsX 本体と Spawn のみ更新対象になります。

---

## 💡 ヒント

* バックアップはすべて `~/minecraft/backups/` 以下に保存されます。
* プラグイン追加時は `plugins_list.txt` に `.jar` 名を追記してください。
* Hangar, GitHub, Modrinth API を利用して自動で最新版を取得します。

---

## 📜 ライセンス

MIT License

---
