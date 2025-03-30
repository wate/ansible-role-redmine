redmine
=================

Setup redmine

OS Platform
-----------------

### Debian

- bookworm

Role Variables
--------------

### [defaults/main.yml](defaults/main.yml)

設定方法の詳細については[defaults/main.yml](defaults/main.yml)のサンプルコードなどを参照してください。

#### `redmine_repo`

Redmineのリポジトリ

#### `redmine_version`

Redmineのバージョン(ブランチ名)

#### `redmine_additional_environment`

追加の環境設定

#### `redmine_gemfile_local_packages`

追加インストールするgemパッケージ

#### `redmine_mode`

Redmineの動作モード

#### `redmine_db_cfg`

Redmineのデータベース設定(config/database.yml)

#### `redmine_cfg`

config/configuration.ymlの設定

#### `redmine_puma_extra_cfg`

Pumaの追加設定

#### `redmine_gem_path`

Gemパッケージのインストール先

#### `redmine_bundler_job`

bundle install/update実行時の並列ジョブ数

#### `redmine_lang`

Redmineの標準の言語設定

#### `redmine_themes`

インストールするテーマ

#### `redmine_plugins`

インストールするプラグイン

#### `redmine_admin`

デフォルトの「システム管理者」の設定

#### `redmine_statuses`

「チケットのステータス」の設定

#### `redmine_trackers`

「トラッカー」の設定

#### `redmine_roles`

「ロール」の設定

#### `redmine_priorities`

「チケットの優先度」の設定

#### `redmine_document_categories`

「文書カテゴリ」」の設定

#### `redmine_time_entry_activities`

「作業分類」」の設定

#### `redmine_issue_custom_fields`

「チケット」の「カスタムフィールド」の設定

#### `redmine_project_custom_fields`

「プロジェクト」の「カスタムフィールド」の設定

#### `redmine_user_custom_fields`

「ユーザー」の「カスタムフィールド」の設定

#### `redmine_settings`

Redmineの設定

#### `redmine_workflows`

「ワークフロー」の設定

#### `redmine_field_permissions`

「フィールドの権限」の設定

#### `redmine_users`

「ユーザー」の設定

#### `redmine_groups`

「グループ」の設定

#### `redmine_issue_queries`

「チケット」の「カスタムクエリ」の設定

#### `redmine_project_queries`

「プロジェクト」の「カスタムクエリ」の設定

#### `redmine_projects`

「プロジェクト」の設定

#### `redmine_attachments`

「添付ファイル」の設定

#### `redmine_message_customize`

「message customizeプラグイン」の設定

#### `redmine_view_customize`

「view customizeプラグイン」に登録するデータ

#### `redmine_issue_templates`

「グローバルチケットテンプレート」に登録するデータ

#### `redmine_note_templates`

「グローバルノートテンプレート」に登録するデータ

#### `redmine_cron_vars`

Redmineのcron用変数

#### `redmine_cron_jobs`

Redmineのcron設定

#### `redmine_skip_load_default_data`

インストール時にデフォルトデータのロードをスキップするか否か

#### `redmine_envs`

その他の環境変数  
※「RAILS_ENV」にはredmine_mode変数の値が、「REDMILE_LANG」にはredmine_lang変数の値が設定されます

#### `redmine_register_sidekiq_service`

sidekiqのサービス化を行うか否か

#### `redmine_sidekiq_service_dependencies`

sidekiqサービスの依存関係  
※SystemdのユニットファイルのAfter句に定義する依存サービスを指定します

#### `redmine_customize_base_dir`

カスタマイズ設定用ベースディレクトリ

#### `redmine_customize_message_dir`

メッセージのカスタマイズ設定格納用ディレクトリ

#### `redmine_customize_message`

メッセージのカスタマイズ設定

#### `redmine_customize_view_path_dir`

ビューファイルのカスタマイズ設定格納用ディレクトリ

#### `redmine_restore`

Redmineのバックアップデータのリストア  
新規設置時または変数「redmine_restore」にtrueが設定されており、  
変数「redmine_restore_files_archive_file」または「redmine_restore_database_dump_file」に  
リストアデータのパスが設定されている場合のみ実行されます。  
※変数のパスにファイルが存在しない場合、リストア処理はスキップされます。

### [vars/main.yml](vars/main.yml)

設定値については[vars/main.yml](vars/main.yml)を参照してください。

#### `redmine_dependency_packages`

#### `redmine_mysql2_dependency_packages`

#### `redmine_postgresql_dependency_packages`

#### `redmine_user`

#### `redmine_group`

#### `redmine_root`

#### `redmine_tmp_dir`

#### `redmine_config_dir`

#### `redmine_theme_dir`

#### `redmine_plugin_dir`

#### `redmine_bin_dir`

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
