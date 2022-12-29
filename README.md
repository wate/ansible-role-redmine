redmine
=================

Setup redmine

OS Platform
-----------------

### Debian

- bullseye

Role Variables
--------------

### `redmine_repo`

Redmineのリポジトリ

### `redmine_version`

Redmineのバージョン(ブランチ名)

### `redmine_additional_environment`

追加の環境設定

### `redmine_gemfile_local_content`

追加でインストールするgemパッケージ

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

### `redmine_lang`

Redmineの標準の言語設定

### `redmine_themes`

Redmineにインストールするテーマ

### `redmine_plugins`

Redmineにインストールするプラグイン

### `redmine_settings`

Redmineの全体設定

### `redmine_cron_vars`

Redmineのcron用変数

### `redmine_cron_jobs`

Redmineのcron設定

### `redmine_custom_script_files`

カスタムスクリプトのアップロード設定

### `redmine_admin`

デフォルトのシステム管理者設定

### `redmine_issue_statuses`

チケットのステータス

### `redmine_trackers`

トラッカー

### `redmine_priorities`

チケットの優先度

### `redmine_document_categories`

文書カテゴリ

### `redmine_time_entry_activities`

作業分類

### `redmine_custom_queries`

カスタムクエリ

### `redmine_workflows`

ワークフロー

### `redmine_workflow_permissions`

フィールドの権限

### `redmine_roles`

ロールと権限

### `redmine_project_custom_fields`

カスタムフィールド(プロジェクト)

### `redmine_user_custom_fields`

カスタムフィールド(ユーザー)

### `redmine_issue_custom_fields`

カスタムフィールド(チケット)

### `redmine_users`

ユーザー

### `redmine_groups`

グループ

### `redmine_projects`

プロジェクト

### `redmine_attachments`

添付ファイル

### `redmine_message_customize`

message customizeプラグイン

### `redmine_view_customize`

view customizeプラグイン

### `redmine_issue_templates`

issue templatesプラグインのグルーバルチケットテンプレート

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
