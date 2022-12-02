redmine
=================

setup redmine

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

### `redmine_gemfile_local_content`

追加でインストールするgemパッケージ

### `redmine_db_cfg`

Redmineのデータベース設定(config/database.yml)

### `redmine_cfg`

config/configuration.ymlの設定

### `redmine_puma_extra_cfg`

Pumaの追加設定

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

### `redmine_reimport`

2回目以降の再インポート判定

### `redmine_reimport_admin`

### `redmine_reimport_attachment`

### `redmine_reimport_all`

### `redmine_reimport_issue_status`

### `redmine_reimport_tracker`

### `redmine_reimport_setting`

### `redmine_reimport_role`

### `redmine_reimport_issue_custom_field`

### `redmine_reimport_project_custom_field`

### `redmine_reimport_user_custom_field`

### `redmine_reimport_priority`

### `redmine_reimport_document_category`

### `redmine_reimport_time_entry_activity`

### `redmine_reimport_custom_query`

### `redmine_reimport_workflow`

### `redmine_reimport_workflow_permission`

### `redmine_reimport_user`

### `redmine_reimport_group`

### `redmine_reimport_project`

### `redmine_reimport_message_customize`

### `redmine_reimport_view_customize`

### `redmine_reimport_issue_templates`

### `redmine_reimport_issue_templates_note`

### `redmine_restore`

Redmineのリストア設定  
※新規設置時または変数「redmine_restore」にtrueが設定されている場合にのみ実行されます。  
※変数「redmine_restore_files_archive_file」と「redmine_restore_database_dump_file」に設定されたパスにファイルが存在しない場合は実行されません。

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
