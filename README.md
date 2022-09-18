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

Redmineの設定(config/configuration.yml)

### `redmine_puma_extra_cfg`

Rumaの追加設定

### `redmine_lang`

Redmineの標準の言語設定

### `redmine_themes`

Redmineにインストールするテーマの設定

### `redmine_plugins`

Redmineにインストールするプラグインの設定

### `redmine_settings`

Redmineの設定(管理)

### `redmine_cron_vars`

Redmineのcron用変数設定

### `redmine_cron_jobs`

Redmineのcron設定

### `redmine_custom_script_files`

カスタムスクリプトのアップロード設定

### `redmine_admin`

Redmineの設定(システム管理者)

### `redmine_issue_statuses`

Redmineの設定(チケットのステータス)

### `redmine_trackers`

Redmineの設定(トラッカー)

### `redmine_priorities`

Redmineの設定(チケットの優先度)

### `redmine_document_categories`

Redmineの設定(文書カテゴリ)

### `redmine_time_entry_activities`

Redmineの設定(作業分類)

### `redmine_custom_queries`

Redmineの設定(カスタムクエリ)

### `redmine_workflows`

Redmineの設定(ワークフロー)

### `redmine_workflow_permissions`

Redmineの設定(ワークフロー：フィールドの権限)

### `redmine_roles`

Redmineの設定(ロールと権限)

### `redmine_project_custom_fields`

Redmineの設定(カスタムフィールド[プロジェクト])

### `redmine_user_custom_fields`

Redmineの設定(カスタムフィールド[ユーザー])

### `redmine_issue_custom_fields`

Redmineの設定(カスタムフィールド[チケット])

### `redmine_users`

Redmineの設定(ユーザー)

### `redmine_groups`

Redmineの設定(グループ)

### `redmine_projects`

Redmineの設定(プロジェクト)

### `redmine_attachments`

Redmineの設定(添付ファイル)

### `redmine_message_customize`

Redmineの設定(message customizeプラグイン)

### `redmine_view_customize`

Redmineの設定(view customizeプラグイン)

### `redmine_issue_templates`

Redmineの設定(issue templatesプラグインのグルーバルチケットテンプレート)

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
