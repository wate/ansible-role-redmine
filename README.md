redmine
=================

Setup redmine

OS Platform
-----------------

### Debian

- bookworm

Role Variables
--------------

設定方法の詳細については[defaults/main.yml](defaults/main.yml)のサンプルコードを参照してください。

### `redmine_repo`

Redmineのリポジトリ

### `redmine_version`

Redmineのバージョン(ブランチ名)

### `redmine_additional_environment`

追加の環境設定

### `redmine_mode`

Redmineの動作モード

### `redmine_db_cfg`

Redmineのデータベース設定(config/database.yml)

### `redmine_cfg`

config/configuration.ymlの設定

### `redmine_puma_extra_cfg`

Pumaの追加設定

### `redmine_gem_path`

Gemパッケージのインストール先

### `redmine_bundler_job`

bundle install/update実行時の並列ジョブ数

### `redmine_lang`

Redmineの標準の言語設定

### `redmine_themes`

インストールするテーマ

### `redmine_plugins`

インストールするプラグイン

### `redmine_admin`

デフォルトの「システム管理者」の設定

### `redmine_statuses`

「チケットのステータス」の設定

### `redmine_trackers`

「トラッカー」の設定

### `redmine_roles`

「ロール」の設定

### `redmine_priorities`

「チケットの優先度」の設定

### `redmine_document_categories`

「文書カテゴリ」」の設定

### `redmine_time_entry_activities`

「作業分類」」の設定

### `redmine_issue_custom_fields`

「チケット」の「カスタムフィールド」の設定

### `redmine_project_custom_fields`

「プロジェクト」の「カスタムフィールド」の設定

### `redmine_user_custom_fields`

「ユーザー」の「カスタムフィールド」の設定

### `redmine_settings`

Redmineの設定

### `redmine_workflows`

「ワークフロー」の設定

### `redmine_field_permissions`

「フィールドの権限」の設定

### `redmine_users`

「ユーザー」の設定

### `redmine_groups`

「グループ」の設定

### `redmine_issue_queries`

「チケット」の「カスタムクエリ」の設定

### `redmine_project_queries`

「プロジェクト」の「カスタムクエリ」の設定

### `redmine_projects`

「プロジェクト」の設定

### `redmine_attachments`

「添付ファイル」の設定

### `redmine_message_customize`

「message customizeプラグイン」の設定

### `redmine_view_customize`

「view customizeプラグイン」に登録するデータ

### `redmine_issue_templates`

「グローバルチケットテンプレート」に登録するデータ

### `redmine_note_templates`

「グローバルノートテンプレート」に登録するデータ

### `redmine_cron_vars`

Redmineのcron用変数

### `redmine_cron_jobs`

Redmineのcron設定

### `redmine_skip_load_default_data`

Redmineインストール時にデフォルトデータのロードをスキップする

### `redmine_restore`

Redmineのバックアップデータのリストア  
新規設置時または変数「redmine_restore」にtrueが設定されており、  
変数「redmine_restore_files_archive_file」または「redmine_restore_database_dump_file」に  
リストアデータのパスが設定されている場合のみ実行されます。  
※変数のパスにファイルが存在しない場合、リストア処理はスキップされます。

Example Playbook
--------------

```yaml
- hosts: servers
  roles:
    - role: redmine
```

License
--------------

Apache License 2.0
