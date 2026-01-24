IMPORT_DATA_DIR = ENV['IMPORT_DATA_DIR'] || File.join(Rails.root, 'tmp')

# 管理ユーザーのID
ADMIN_USER_ID = 1

# 許可されるカスタムフィールド形式
ALLOW_FIELD_FORMATS = [
  'string',
  'text',
  'link',
  'date',
  'list',
  'int',
  'float',
  'bool',
  'version',
  'user',
  'attachment',
  'enumeration'
].map(&:freeze).freeze

# チケット権限タイプ
ISSUE_PERMISSION_TYPES = %w[
  view_issues
  add_issues
  edit_issues
  add_issue_notes
  delete_issues
].freeze

# ユーザー設定値
MAIL_NOTIFICATION_VALUES = %w[
  selected
  only_my_events
  only_assigned
  only_owner
  none
].freeze

COMMENTS_SORTING_VALUES = %w[asc desc].freeze
TEXTAREA_FONT_VALUES = %w[monospace proportional].freeze

namespace :redmine do
  # 共通ヘルパーメソッド
  module ImportHelpers
    # データファイルを読み込んでインポート処理を実行する共通メソッド
    def import_with_data_file(filename, title, delete: true)
      data_file = File.join(IMPORT_DATA_DIR, filename)
      data = load_data(data_file)

      return unless data.present?

      puts "\nImport #{title}\n#{'-' * 23}\n\n"
      yield(data)
    ensure
      FileUtils.rm_f(data_file) if delete && !ENV['IMPORT_DATA_FILE_NO_DELETE']
    end

    # IDまたは名前でレコードを検索または初期化する共通メソッド
    def find_or_initialize_record(klass, data, id_key: 'id', name_key: 'name')
      if data[id_key].present?
        klass.find_or_initialize_by(id: data[id_key])
      elsif data[name_key].present?
        klass.find_or_initialize_by(name: data[name_key])
      else
        klass.new
      end
    end

    # 名前のリストからIDのリストに変換する共通メソッド
    def names_to_ids(klass, names)
      return [] unless names.present?
      klass.where(name: names).pluck(:id).map(&:to_s)
    end

    # 真偽値を安全に変換する共通メソッド
    def to_bool(value)
      return value if [true, false].include?(value)
      !!value
    end

    # トラッカー名のリストからトラッカーID文字列のリストに変換する共通メソッド（N+1クエリを回避）
    def process_permissions_trackers(permissions_trackers_data)
      permissions_all_trackers = Hash[ISSUE_PERMISSION_TYPES.map { |type| [type, '1'] }]
      permissions_tracker_ids = Hash[ISSUE_PERMISSION_TYPES.map { |type| [type, []] }]

      return [permissions_all_trackers, permissions_tracker_ids] unless permissions_trackers_data.present?

      # 全トラッカー名を一度に取得してN+1を回避
      all_tracker_names = permissions_trackers_data.values.flatten.uniq
      trackers_by_name = Tracker.where(name: all_tracker_names).index_by(&:name)

      ISSUE_PERMISSION_TYPES.each do |permission_type|
        next unless permissions_trackers_data.key?(permission_type)

        tracker_names = permissions_trackers_data[permission_type]
        tracker_ids = tracker_names.map { |name| trackers_by_name[name]&.id }.compact
        permissions_tracker_ids[permission_type] = tracker_ids.map(&:to_s)
        permissions_all_trackers[permission_type] = '0'
      end

      [permissions_all_trackers, permissions_tracker_ids]
    end
  end

  extend ImportHelpers

  desc 'Redmineの各種設定のインポート'
  task :import do
    %w[
      admin
      status
      tracker
      role
      priority
      document_category
      time_entry_activity
      issue_custom_field
      project_custom_field
      user_custom_field
      setting
      workflow
      field_permission
      user
      group
      issue_query
      project_query
      time_entry_query
      project
      attachment
      plugin
    ].each do |task|
      Rake::Task["redmine:import:#{task}"].invoke
    end
  end
  namespace :import do
    desc '「システム管理者」を更新します'
    task :admin => :environment do
      import_with_data_file('admin.yml', 'admin', delete: !ENV['IMPORT_ADMIN_DATA_FILE_NO_DELETE']) do |data|
        admin = User.find(ADMIN_USER_ID)
        admin.assign_attributes(data.slice('login', 'firstname', 'lastname', 'mail', 'language', 'mail_notification'))
        if data.key?('password')
          admin.password = data['password']
          admin.password_confirmation = data['password']
        end
        admin.must_change_passwd = to_bool(data['must_change_passwd']) if data.key?('must_change_passwd')
        admin.save!
        pp admin
      end
    end
    desc '「チケットのステータス」をインポートします'
    task :status => :environment do
      import_with_data_file('status.yml', 'status') do |statuses|
        statuses.each do |data|
          status = find_or_initialize_record(IssueStatus, data)
          status.safe_attributes = data
          status.position = data['position'] if data['position'].present?
          status.save!
          puts "* #{status}"
        end
      end
    end
    desc '「トラッカー」をインポートします'
    task :tracker => :environment do
      import_with_data_file('tracker.yml', 'tracker') do |trackers|
        default_issue_status = IssueStatus.first
        # ワークフローのコピー元の指定がないトラッカーから先に登録
        import_trackers = trackers.reject {|item| item['copy_workflow_from'].present? }
        import_trackers.concat trackers.select {|item| item['copy_workflow_from'].present? }
        import_trackers.each do |data|
          tracker = find_or_initialize_record(Tracker, data)
          if tracker.new_record?
            tracker.core_fields = [
              'assigned_to_id',
              'category_id',
              'fixed_version_id',
              'parent_issue_id',
              'start_date',
              'due_date',
              'estimated_hours',
              'done_ratio',
              'description'
            ]
          end
          tracker.name = data['name']
          tracker.core_fields = data['enabled_standard_fields'] if data['enabled_standard_fields'].present?
          tracker.description = data['description'] if data.key?('description')
          tracker.default_status_id = default_issue_status.id
          tracker.is_in_roadmap = to_bool(data['is_in_roadmap']) if data.key?('is_in_roadmap')
          if data['default_status'].present?
            issue_status = if data['default_status'].is_a?(Hash)
              find_or_initialize_record(IssueStatus, data['default_status'])
            else
              IssueStatus.find_by(name: data['default_status'])
            end
            tracker.default_status_id = issue_status.id if issue_status
          end
          tracker.position = data['position'] if data['position'].present?
          tracker.save!
          if data['copy_workflow_from'].present?
            copy_from = Tracker.find_by(name: data['copy_workflow_from'])
            tracker.copy_workflow_rules(copy_from) if copy_from
          end
          puts "* #{tracker}"
        end
      end
    end
    desc '「ロール」をインポートします'
    task :role => :environment do
      import_with_data_file('role.yml', 'role') do |roles|
        roles.each do |data|
          role = find_or_initialize_record(Role, data)
          is_new = role.new_record?
          if is_new
            role.assignable = true
            role.issues_visibility = 'default'
            role.users_visibility = 'all'
            role.time_entries_visibility = 'all'
          end
          role.name = data['name']
          # このロールにチケットを割り当て可能
          role.assignable = data['assignable'] if data.key?('assignable')
          # 表示できるチケット
          role.issues_visibility = data['issues_visibility'] if data.key?('assignable')
          # 表示できるユーザー
          role.users_visibility = data['users_visibility'] if data.key?('assignable')
          # 表示できる作業時間
          if data.key?('time_entries_visibility')
            role.time_entries_visibility = data['time_entries_visibility']
          end
          # 権限
          role.permissions = data['permissions'].map(&:to_sym) if data.key?('permissions')
          # 権限(追加)
          if data.key?('append_permissions')
            role.permissions.concat data['append_permissions'].map(&:to_sym)
          end
          # メンバーの管理
          role.all_roles_managed = '1'
          role.managed_role_ids = []
          if data.key?('managed_roles') && data['permissions'].include?('manage_members')
            role.all_roles_managed = '0'
            role.managed_role_ids = Role.where(name: data['managed_roles']).pluck(:id)
          end

          # トラッカーごとの権限設定（N+1クエリを回避）
          permissions_all_trackers, permissions_tracker_ids = process_permissions_trackers(data['permissions_trackers'])
          role.permissions_all_trackers = permissions_all_trackers
          role.permissions_tracker_ids = permissions_tracker_ids
          # 並び順
          role.position = data['position'] if data.key?('position')
          role.save!
          # 新規登録時のみワークフローのコピーを実行
          if is_new && data.key?('copy_workflow_from')
            copy_from = Role.find_by(name: data['copy_workflow_from'])
            role.copy_workflow_rules(copy_from) if copy_from
          end
          puts "* #{role}"
        end
      end
    end
    desc '「チケットの優先度」をインポートします'
    task :priority => :environment do
      import_with_data_file('priority.yml', 'priority') do |priorities|
        priorities.each do |data|
          priority = find_or_initialize_record(IssuePriority, data)
          priority.active = true if priority.new_record?
          import_enumeration priority, data
        end
      end
    end
    desc '「文書カテゴリ」をインポートします'
    task :document_category => :environment do
      import_with_data_file('document_category.yml', 'document category') do |document_categories|
        document_categories.each do |data|
          document_category = find_or_initialize_record(DocumentCategory, data)
          document_category.active = true if document_category.new_record?
          import_enumeration document_category, data
        end
      end
    end
    desc '「作業分類」をインポートします'
    task :time_entry_activity => :environment do
      import_with_data_file('time_entry_activity.yml', 'time entry activity') do |time_entry_activities|
        time_entry_activities.each do |data|
          time_entry_activity = find_or_initialize_record(TimeEntryActivity, data)
          time_entry_activity.active = true if time_entry_activity.new_record?
          import_enumeration time_entry_activity, data
        end
      end
    end
    desc '「チケット」の「カスタムフィールド」をインポートします'
    task :issue_custom_field => :environment do
      import_with_data_file('issue_custom_field.yml', 'issue custom field', delete: !ENV['IMPORT_DEBUG']) do |custom_fields|
        custom_fields.each do |data|
          next unless ALLOW_FIELD_FORMATS.include?(data['field_format'])

          cf = IssueCustomField.find_or_initialize_by(name: data['name'])
          import_custom_field cf, data
        end
      end
    end
    desc '「プロジェクト」の「カスタムフィールド」をインポートします'
    task :project_custom_field => :environment do
      import_with_data_file('project_custom_field.yml', 'project custom field') do |custom_fields|
        custom_fields.each do |data|
          next unless ALLOW_FIELD_FORMATS.include?(data['field_format'])

          cf = ProjectCustomField.find_or_initialize_by(name: data['name'])
          import_custom_field cf, data
        end
      end
    end
    desc '「ユーザー」の「カスタムフィールド」をインポートします'
    task :user_custom_field => :environment do
      import_with_data_file('user_custom_field.yml', 'user custom field') do |custom_fields|
        custom_fields.each do |data|
          next unless ALLOW_FIELD_FORMATS.include?(data['field_format'])

          cf = UserCustomField.find_or_initialize_by(name: data['name'])
          import_custom_field cf, data
        end
      end
    end
    desc 'Redmine本体およびプラグイン設定をインポートします'
    task :setting => :environment do
      import_with_data_file('setting.yml', 'setting') do |redmine_setting|
        ## Redmine本体の設定をインポート
        core_setting = redmine_setting.reject { |key, value| key.start_with?('plugin_') }
        if core_setting.key?('default_projects_trackers')
          core_setting['default_projects_tracker_ids'] = Tracker.where(name: core_setting['default_projects_trackers']).pluck(:id).map { |item| item.to_s }
          core_setting.delete('default_projects_trackers')
        end
        if core_setting.key?('new_project_user_role') && core_setting['new_project_user_role'].present?
          assigne_role = Role.find_by(name: core_setting['new_project_user_role'])
          core_setting['new_project_user_role_id'] = assigne_role.id if assigne_role
          core_setting.delete('new_project_user_role')
        end
        if core_setting.present?
          Setting.set_all_from_params(core_setting)
          puts "\n### Core setting\n"
          puts core_setting
        end
        ## プラグインの設定をインポート
        plugin_setting = redmine_setting.select {|key, value| key.start_with?('plugin_') }
        puts plugin_setting
        if plugin_setting.present?
          plugin_setting.each do |key, value|
            if Redmine::Plugin.installed? key.sub('plugin_', '').to_s
              Setting.send(key + '=', value.with_indifferent_access)
            end
          end
          puts "\n### Plugin setting\n"
          puts plugin_setting
        end
      end
    end
    desc '「ワークフロー」をインポートします'
    task :workflow => :environment do
      import_with_data_file('workflow.yml', 'workflow') do |workflows|
        all_statuses = IssueStatus.all
        workflows.each do |data|
          roles = Role.where(:name =>  data['roles']).to_a
          trackers = Tracker.where(:name =>  data['trackers']).to_a

          transitions = {}
          status_ids = all_statuses.pluck(:id).map { |item| item.to_s }
          status_ids.prepend '0'
          status_ids.each do |status_id|
            all_statuses.each do |status|
              transitions[status_id] = {} unless transitions.key?(status_id)
              transitions[status_id][status.id.to_s] = {'always' => false, 'author' => false, 'assignee' => false}
            end
          end
          data['transitions'].each do |transition|
            from_status_id = '0'
            if transition['from']
              from_status = IssueStatus.find_by(name: transition['from'])
              from_status_id = from_status.id.to_s if from_status
            end
            to_statuses = IssueStatus.where(:name => transition['to'])
            to_statuses.each do |to_status|
              to_status_id = to_status.id.to_s
              transitions[from_status_id][to_status_id]['always'] = true
            end
          end
          WorkflowTransition.replace_transitions(trackers, roles, transitions)
          puts({'tracker' => trackers.pluck(:name), 'role' => roles.pluck(:name), 'transition' => transitions})
        end
      end
    end
    desc '「フィールドの権限」をインポートします'
    task :field_permission => :environment do
      import_with_data_file('field_permission.yml', 'workflow permission') do |field_permissions|
        all_statuses = IssueStatus.all
        status_ids = all_statuses.pluck(:id).map { |item| item.to_s }
        permission_fields = {
          'project' => {
            'name' => 'project_id',
            'values' =>['readonly']
          },
          'tracker' => {
            'name' => 'tracker_id',
            'values' =>['readonly']
          },
          'subject' => {
            'values' => ['readonly']
          },
          'description' => {
            'values' => ['readonly', 'required']
          },
          'priority' => {
            'name' => 'priority_id',
            'values' => ['readonly']
          },
          'assigned_to' => {
            'name' => 'assigned_to_id',
            'values' => ['readonly', 'required']
          },
          'category' => {
            'name' => 'category_id',
            'values' => ['readonly', 'required']
          },
          'fixed_version' => {
            'name' =>'fixed_version_id',
            'values' => ['readonly', 'required']
          },
          'parent_issue' => {
            'name' => 'parent_issue_id',
            'values' => ['readonly', 'required']
          },
          'start_date' => {
            'values' => ['readonly', 'required']
          },
          'due_date' => {
            'values' => ['readonly', 'required']
          },
          'estimated_hours' => {
            'values' => ['readonly', 'required']
          },
          'done_ratio' => {
            'values' => ['readonly', 'required']
          },
          'is_private' => {
            'values' => ['readonly', 'required']
          }
        }
        field_permissions.each do |data|
          roles = Role.where(:name => data['roles'])
          trackers = Tracker.where(:name => data['trackers'])
          permissions = {}
          status_ids.each do |status_id|
            permissions[status_id] = {} unless permissions.key?(status_id)
            permission_fields.each do |key, value|
              field_name = value['name'] || key
              permissions[status_id][field_name] = 'no_change'
            end
          end
          core_fields = permission_fields.keys
          data['permissions'].each do |setting|
            update_fields = setting['fields']
            update_fields = [update_fields] unless update_fields.is_a?(Array)
            custom_field_names = update_fields.reject {|field| core_fields.include?(field) }
            if custom_field_names.present?
              custom_fields = IssueCustomField.where(:name => custom_field_names)
            end
            update_status_ids = IssueStatus.where(:name => setting['statuses']).pluck(:id).map { |item| item.to_s }
            update_status_ids.each do |update_status_id|
              update_fields.each do |update_field|
                field_name = update_field
                if permission_fields.key?(field_name)
                  field_name = permission_fields[field_name]['name'] if permission_fields[field_name].key?('name')
                  permissions[update_status_id][field_name] = setting['permission']
                end
                if custom_fields.present?
                  custom_fields.each do |cf|
                    permissions[update_status_id][cf.id] = setting['permission']
                  end
                end
              end
            end
          end
          permissions.each_value do |rule_by_status_id|
            rule_by_status_id.reject! {|status_id, rule| rule == 'no_change'}
          end
          WorkflowPermission.replace_permissions(trackers, roles, permissions)
          puts({'tracker' => trackers.pluck(:name), 'role' => roles.pluck(:name), 'permission' => permissions})
        end
      end
    end
    desc '「ユーザー」をインポートします'
    task :user => :environment do
      import_with_data_file('user.yml', 'user') do |users|
        users.each do |login, data|
          user = User.find_by(login: login)
          if user
            # 既存ユーザー情報の更新
            user.firstname = data['firstname'] if data.key?('firstname')
            user.lastname = data['lastname'] if data.key?('lastname')
            user.mail = data['mail'] if data.key?('mail')
            if data.key?('password') && data['password'].present?
              user.password = data['password']
              user.password_confirmation = data['password']
            end
          else
            # ユーザーの新規登録
            user = User.new(:language => Setting.default_language, :mail_notification => Setting.default_notification_option)
            user.login = login
            # 名
            user.firstname = data['firstname']
            # 姓
            user.lastname = data['lastname']
            # メールアドレス
            user.mail = data['mail']
            user.generate_password = true
            if data.key?('password') && data['password'].present?
              user.password = data['password']
              user.password_confirmation = data['password']
              user.generate_password = false
            end
          end
          # 言語
          user.language = data['language'] if data.key?('language')
          # システム管理者
          user.admin = to_bool(data['admin']) if data.key?('admin') && user.id != ADMIN_USER_ID
          # 次回ログイン時にパスワード変更を強制
          user.must_change_passwd = to_bool(data['must_change_passwd']) if data.key?('must_change_passwd')
          # メール通知
          if data.key?('mail_notification') && MAIL_NOTIFICATION_VALUES.include?(data['mail_notification'])
            user.mail_notification = data['mail_notification']
          end
          # UserPreference
          # ------------------
          # 優先度が 高い 以上のチケットについても通知
          user.pref.notify_about_high_priority_issues = to_bool(data['notify_about_high_priority_issues']) if data.key?('notify_about_high_priority_issues')
          # 自分自身による変更の通知は不要
          user.pref.no_self_notified = data['no_self_notified'] if data.key?('no_self_notified')
          # オートウォッチ
          if data.key?('auto_watch_on')
            data['auto_watch_on'] = [] unless data['auto_watch_on']
            user.pref.auto_watch_on = data['auto_watch_on']
          end
          # メールアドレスを隠す
          user.pref.hide_mail = data['hide_mail'] if data.key?('hide_mail')
          # コメントの表示順
          if data.key?('comments_sorting') && COMMENTS_SORTING_VALUES.include?(data['comments_sorting'])
            user.pref.comments_sorting = data['comments_sorting']
          end
          # データを保存せずにページから移動するときに警告
          user.pref.warn_on_leaving_unsaved = data['warn_on_leaving_unsaved'].to_bool if data.key?('warn_on_leaving_unsaved')
          # テキストエリアのフォント
          if data.key?('textarea_font') && TEXTAREA_FONT_VALUES.include?(data['textarea_font'])
            user.pref.textarea_font = data['textarea_font']
          end
          # カスタムフィールド
          # ------------------
          if data.key?('custom_fields')
            custom_field_values = {}
            data['custom_fields'].each do |custom_field|
              cf = find_or_initialize_record(UserCustomField, custom_field)
              custom_field_values[cf.id] = custom_field['value'] if cf && !cf.new_record?
            end
            user.custom_field_values = custom_field_values
          end
          if data.key?('locked')
            user.status = data['locked'] ? User::STATUS_LOCKED : User::STATUS_ACTIVE
          end
          user.save!
          puts "* #{user}"
        end
      end
    end
    desc '「グループ」をインポートします'
    task :group => :environment do
      import_with_data_file('group.yml', 'group') do |groups|
        groups.each do |data|
          group = find_or_initialize_record(Group, data, name_key: 'lastname')
          group.name = data['name']
          group.save!
          if data['users'].present?
            group.users = User.where(login: data['users']).to_a
          end
          puts "* #{group}"
        end
      end
    end
    desc '「チケット」の「カスタムクエリ」をインポートします'
    task :issue_query => :environment do
      # TODO: 他のカスタムクエリの登録処理と共通処理を統合し最適化する必要あり
      # description/filters/columns/group_by/sortなど共通の処理が多いため、
      # この部分ではチケットクエリ固有のfiltersパラメーターの変換処理のみを行う形に変更し、
      # カスタムクエリの登録については別途定義した共通処理を呼び出す形にする
      import_with_data_file('issue_query.yml', 'issue query') do |custom_queries|
        custom_queries.each do |data|
          project = nil
          if data['project']
            project = Project.find_by_identifier(data['project']) || Project.find_by_name(data['project'])
          end
          import_issue_query data, project
        end
      end
    end
    desc '「プロジェクト」の「カスタムクエリ」をインポートします'
    task :project_query => :environment do
      # TODO: 他のカスタムクエリの登録処理と共通処理を統合し最適化する必要あり
      # description/filters/columns/group_by/sortなど共通の処理が多いため、
      # この部分ではプロジェククエリ固有のfiltersパラメーターの変換処理のみを行う形に変更し、
      # カスタムクエリの登録については別途定義した共通処理を呼び出す形にする
      import_with_data_file('project_query.yml', 'project query') do |project_queries|
        project_queries.each do |data|
          project_query = find_or_initialize_record(ProjectQuery, data)
          if project_query.new_record?
            project_query.visibility = Query::VISIBILITY_PUBLIC
            project_query.user = User.find(ADMIN_USER_ID)
          end
          project_query.name = data['name']
          project_query.project = nil
          ## フィルター
          filter_fields = []
          filter_operators = {}
          filter_values = {}
          data['filters'].each do |key, value|
            field_name = key
            field_filter_operator = value['operator'] || value['op']
            field_filter_value = value['values'] || []
            case key
            when 'id'
              field_name = 'id'
              has_mine = field_filter_value.include?('mine')
              has_bookmarks = field_filter_value.include?('bookmarks')
              field_filter_value = User.where(:login => field_filter_value).pluck(:id).map {|item| item.to_s }
              field_filter_value.push 'mine' if has_mine
              field_filter_value.push 'bookmarks' if has_bookmarks
            end
            filter_fields.push field_name
            filter_operators[field_name] = field_filter_operator
            filter_values[field_name] = field_filter_value
          end
          form_params = {
            c: [],
            visibility: Query::VISIBILITY_PUBLIC,
            display_type: 'bord'
          }
          ## フィルター
          form_params[:fields] = filter_fields
          form_params[:operators] = filter_operators
          form_params[:values] = filter_values
          ## 説明
          if data.key?('description') && data['description'].present?
            form_params[:description] = data['description']
          end
          ## 表示
          form_params[:visibility] = to_bool(data['visibility']) ? Query::VISIBILITY_PUBLIC : Query::VISIBILITY_PRIVATE if data.key?('visibility')
          ## 表示形式
          form_params[:display_type] = data['display_type'] if data.key?('display_type')
          ## グループ条件
          form_params[:group_by] = data['group_by'] if data.key?('group_by')
          ## 表示項目
          if data.key?('columns') && data['columns'].present?
            form_params[:c] = data['columns']
          end
          ## 並び順
          if data.key?('sort') && data['sort'].present?
            form_params[:sort] = []
            data['sort'].each do |sort|
              form_params[:sort].push [sort['field'], sort['order']]
            end
          end
          project_query.build_from_params form_params
          project_query.save!
          puts "* #{project_query.name}"
        end
      end
    end
    desc '「時間管理」の「カスタムクエリ」をインポートします'
    task :time_entry_query => :environment do
      import_with_data_file('time_entry_query.yml', 'time entry query') do |custom_queries|
        custom_queries.each do |data|
          import_time_entry_query data, nil
        end
      end
    end
    desc '「プロジェクト」をインポートします'
    task :project => :environment do
      import_with_data_file('project.yml', 'project') do |projects|
        projects.each do |identifier, data|
          import_project identifier, data
        end
      end
    end
    desc '「添付ファイル」をインポートします'
    task :attachment => :environment do
      import_with_data_file('attachment.yml', 'attachment') do |attachments|
        attachments.each do |data|
          project = Project.find_by_identifier(data['project']) ||
                    Project.find_by_name(data['project']) ||
                    Project.find_by_id(data['project'])
          if project
            container = project
            if data.key?('wiki') && data['wiki'].present?
              container = project.wiki.find_or_new_page(data['wiki'])
            end
            import_attachment container, data
          end
        end
      end
    end
    desc 'プラグインの登録データをインポートします'
    task :plugin => :environment do
      %w[
        message_customize
        view_customize
        issue_template
        note_template
      ].each do |task|
        Rake::Task["redmine:import:plugin:#{task}"].invoke
      end
    end
    namespace :plugin do
      desc 'メッセージカスタマイズのデータをインポートします'
      task :message_customize => :environment do
        if Redmine::Plugin.installed? :redmine_message_customize
          import_with_data_file('message_customize.yml', 'redmine_message_customize setting') do |message_customize_setting|
            lang = ENV['REDMINE_LANG'] || 'ja'
            setting = {}
            setting[lang] = message_customize_setting
            plugin_setting = CustomMessageSetting.find_or_default
            if plugin_setting.update_with_custom_messages_yaml(setting.to_yaml)
              puts setting
            else
              raise "message customize import error"
            end
          end
        end
      end
      desc 'view_customizeのデータをインポートします'
      task :view_customize => :environment do
        if Redmine::Plugin.installed? :view_customize
          import_with_data_file('view_customize.yml', 'view_customize settings') do |settings|
            settings.each do |data|
              view_customize = find_or_initialize_record(ViewCustomize, data, name_key: 'comments')
              view_customize.code = data['code']
              view_customize.path_pattern = data['path_pattern'] if data.key?('path_pattern')
              view_customize.project_pattern = data['project_pattern'] if data.key?('project_pattern')
              view_customize.insertion_position = data['insertion_position'] if data.key?('insertion_position')
              view_customize.customize_type = data['customize_type'] if data.key?('customize_type')
              view_customize.is_enabled = to_bool(data['is_enabled']) ? 1 : 0 if data.key?('is_enabled')
              view_customize.save!
              puts "* #{view_customize.comments}"
            end
          end
        end
      end
      desc 'グローバルチケットテンプレートのデータをインポートします'
      task :issue_template => :environment do
        if Redmine::Plugin.installed? :redmine_issue_templates
          import_with_data_file('issue_template.yml', 'issue template settings') do |issue_templates|
            issue_templates.each do |data|
              tracker = Tracker.find_by(name: data['tracker'])
              next unless tracker

              template = if data['id'].present?
                GlobalIssueTemplate.find_or_initialize_by(id: data['id'])
              else
                GlobalIssueTemplate.find_or_initialize_by(tracker_id: tracker.id, title: data['name'])
              end
              ## トラッカー
              template.tracker_id = tracker.id
              ## テンプレート名
              template.title = data['name']
              ## チケットタイトル
              template.issue_title = data['issue_title'] if data.key?('issue_title')
              ## チケット本文
              template.description = data['description']
              ## デフォルト値
              template.is_default = to_bool(data['is_default']) if data.key?('is_default')
              ## 有効
              template.enabled = to_bool(data['enabled']) if data.key?('enabled')
              ## メモ
              template.note = data['note'] if data.key?('note')
              ## 関連リンク
              template.related_link = data['related_link'] if data.key?('related_link')
              ## 関連リンクのタイトル
              template.link_title = data['link_title'] if data.key?('link_title')
              ## 表示順序
              template.position = data['position'] if data.key?('position')
              template.author = User.find(ADMIN_USER_ID) if template.new_record?
              template.save!
              puts "* #{template.title}"
            end
          end
        end
      end
      desc 'グローバルコメントテンプレートのデータをインポートします'
      task :note_template => :environment do
        if Redmine::Plugin.installed? :redmine_issue_templates
          import_with_data_file('note_template.yml', 'note template settings') do |note_templates|
            note_templates.each do |data|
              tracker = Tracker.find_by(name: data['tracker'])
              next unless tracker

              template = if data['id'].present?
                GlobalNoteTemplate.find_or_initialize_by(id: data['id'])
              else
                GlobalNoteTemplate.find_or_initialize_by(tracker_id: tracker.id, name: data['name'])
              end
              ## トラッカー
              template.tracker_id = tracker.id
              ## テンプレート名
              template.name = data['name']
              ## コメント
              template.description = data['description']
              ## 有効
              template.enabled = to_bool(data['enabled']) if data.key?('enabled')
              ## メモ
              template.memo = data['memo'] if data.key?('memo')
              ## 表示するロール
              if data.key?('roles')
                template.visibility = 1
                template.role_ids = Role.where(:name =>  data['roles']).pluck(:id)
              elsif template.new_record?
                template.visibility = 2
              end
              ## 表示位置
              template.position = data['position'] if data.key?('position')
              template.author = User.find(ADMIN_USER_ID) if template.new_record?
              template.save!
              puts "* #{template.name}"
            end
          end
        end
      end
    end
  end

  ## インポートデータのロード
  def load_data(data_file)
    import_data = nil
    if File.exist?(data_file)
      import_data = YAML.load_file(data_file)
    end
    import_data
  end

  ## 選択肢の値のインポート
  def import_enumeration(enumeration, data)
    enumeration.name = data['name']
    enumeration.active = to_bool(data['active']) if data.key?('active')
    enumeration.is_default = to_bool(data['is_default']) if data.key?('is_default')
    enumeration.position = data['position'] if data.key?('position')
    enumeration.save!
    puts "* #{enumeration}"
  end

  ## カスタムフィールドのインポート
  def import_custom_field(cf, data)
    allow_length_formats = ['string', 'text', 'link', 'int', 'float']
    allow_regexp_formats = ['string', 'text', 'link', 'int', 'float']
    allow_default_value_formats = ['string', 'text', 'link', 'int', 'float', 'date', 'bool']
    allow_text_formatting_formats = ['string', 'text']
    allow_url_pattern_formats = ['string', 'link', 'date', 'int', 'float', 'list', 'bool']
    allow_edit_tag_style_formats = ['version', 'user', 'list', 'bool', 'enumeration']
    allow_multiple_formats = ['version', 'user', 'list', 'enumeration']
    allow_searchable_formats = ['string', 'text', 'list']

    # 形式
    cf.field_format = data['field_format']
    # 名称
    cf.name = data['name']
    # 説明
    cf.description = data['description'] if data.key?('description')
    # 必須
    cf.is_required = to_bool(data['is_required']) if data.key?('is_required')
    # 最小値または最小文字列長
    if data.key?('min_length') && allow_length_formats.include?(data['field_format'])
      cf.min_length = data['min_length'].to_s
    end
    # 最大値値または最小文字列長
    if data.key?('max_length') && allow_length_formats.include?(data['field_format'])
      cf.max_length = data['max_length'].to_s
    end
    # 正規表現
    if data.key?('regexp') && allow_regexp_formats.include?(data['field_format'])
      cf.regexp = data['regexp']
    end
    # 初期値
    if data.key?('default_value') && allow_default_value_formats.include?(data['field_format'])
      cf.default_value = data['default_value'].to_s
    end
    # テキスト書式
    if data.key?('text_formatting') && allow_text_formatting_formats.include?(data['field_format'])
      cf.text_formatting = to_bool(data['text_formatting'])
    end
    # 値に設定するリンクURL
    if data.key?('url_pattern') && allow_url_pattern_formats.include?(data['field_format'])
      cf.url_pattern = data['url_pattern']
    end
    # 表示(入力形式)
    if data.key?('edit_tag_style') && allow_edit_tag_style_formats.include?(data['field_format'])
      edit_tag_style = nil
      if ['check_box', 'radio'].include?(data['edit_tag_style'])
        edit_tag_style = data['edit_tag_style']
        cf.edit_tag_style = edit_tag_style
      end
    end
    # 複数選択
    if data.key?('multiple') && allow_multiple_formats.include?(data['field_format'])
      cf.multiple = to_bool(data['multiple'])
    end
    # 検索対象
    if data.key?('searchable') && allow_searchable_formats.include?(data['field_format'])
      cf.searchable = to_bool(data['searchable'])
    end
    # 選択肢
    if data.key?('possible_values') && data['field_format'] == 'list'
      if data['possible_values'].is_a?(Array)
        choice_values = data['possible_values'].map { |item| item.is_a?(Hash) ? item.value : item }
        possible_values = choice_values.join("\n")
      else
        possible_values = data['possible_values']
      end
      cf.possible_values = possible_values
    end
    # ロール
    if data.key?('user_role') && data['field_format'] == 'user'
      cf.user_role = Role.where(name: data['user_role']).pluck(:id).map {|v| v.to_s }
    end
    # ステータス
    if data.key?('version_status') && data['field_format'] == 'version'
      cf.version_status = data['version_status'].select { |v| ['open', 'locked', 'closed'].include?(v) }
    end
    # 許可する拡張子
    if data.key?('extensions_allowed') && data['field_format'] == 'attachment'
      extensions_allowed = data['extensions_allowed']
      extensions_allowed = data['extensions_allowed'].join(',') if data['extensions_allowed'].is_a?(Array)
      cf.extensions_allowed = extensions_allowed
    end
    # フィルタとして使用
    if data.key?('is_filter') && data['field_format'] != 'attachment'
      cf.is_filter = to_bool(data['is_filter'])
    end
    # 表示
    if data.key?('visible')
      if data['visible'].is_a?(Array)
        cf.role_ids = Role.where(name: data['visible']).pluck(:id).map {|v| v.to_s }
        cf.visible = false
      else
        cf.visible = to_bool(data['visible'])
      end
    end

    # 表示順序
    cf.position = data['position'] if data['position'].present?

    if cf.is_a?(UserCustomField)
      # ユーザーカスタムフィールドの固有処理
      # 編集可能
      cf.editable = true
      if data.key?('editable')
        cf.visible = to_bool(data['editable'])
      end
    end
    if cf.is_a?(IssueCustomField)
      # チケットカスタムフィールドの固有処理
      # トラッカー
      if data.key?('trackers') && data['trackers'].present?
        trackers = data['trackers'].map do |t|
          if t.is_a?(Hash)
            find_or_initialize_record(Tracker, t)
          else
            Tracker.find_by(name: t)
          end
        end
        cf.tracker_ids = trackers.pluck(:id).map {|v| v.to_s }
      end
      # プロジェクト
      cf.is_for_all = true
      if data.key?('projects') && data['projects'].present?
        cf.is_for_all = false
        projects = data['projects'].map do |p|
          if p.is_a?(Hash)
            find_or_initialize_record(Project, p, name_key: 'identifier')
          else
            Project.find_by(name: p)
          end
        end.compact
        cf.project_ids = projects.pluck(:id).map {|v| v.to_s }
      end
    end
    cf.save!
    puts "* #{cf.name}"
  end

  ## プロジェクトのインポート
  def import_project(identifier, data, parent=nil)
    project = Project.find_or_initialize_by(identifier: identifier)
    # 名称
    project.name = data['name'] || identifier
    # 説明
    project.description = data['description'] if data.key?('description')
    # ホームページ
    project.homepage = data['homepage'] if data.key?('homepage')
    # 公開
    project.is_public = data['is_public'] if data.key?('is_public')
    # モジュール
    project.enabled_module_names = data['modules'].uniq if data.key?('modules')
    # メンバーを継承
    project.inherit_members = to_bool(data['inherit_members']) if data.key?('inherit_members')
    # 親プロジェクト
    project.parent_id = parent.id if parent
    # トラッカー
    if data.key?('trackers')
      project.tracker_ids = Tracker.where(:name => data['trackers']).pluck(:id)
    end
    # カスタムフィールド
    if data.key?('custom_fields')
      custom_field_values = {}
      data['custom_fields'].each do |custom_field|
        cf = find_or_initialize_record(ProjectCustomField, custom_field)
        custom_field_values[cf.id] = custom_field['value'] if cf && !cf.new_record?
      end
      project.custom_field_values = custom_field_values
    end
    project.save!
    puts "\n### #{project.name}(#{project.identifier})\n"
    ## メンバー
    if data.key?('members')
      puts "\n#### Import member\n\n"
      project.delete_all_members
      data['members'].each do |member|
        user = User.find_by(login: member['login'])
        role_ids = Role.where(name: member['role']).pluck(:id)
        if user && role_ids.present?
          project_member = Member.new(:project => project, :user_id => user.id)
          project_member.role_ids = role_ids
          project_member.save!
          puts "* #{project_member.user}"
        end
      end
    end
    if data.key?('wiki_pages') && data['wiki_pages'].present?
      puts "\n#### Import wiki page\n\n"
      import_wiki_page(project, data['wiki_pages'])
    end
    if data.key?('wiki_main_page')
      puts "\n#### Set wiki main page\n\n"
      project.wiki.start_page = data['wiki_main_page']
      project.wiki.save!
      puts "* #{project.wiki.start_page}"
    end
    # if data.key?('files') && data['files'].present?
    #   puts "\n#### Import file\n\n"
    #   data['files'].each do |data|
    #     import_attachment project, data
    #   end
    # end
    if data.key?('issue_queries') && data['issue_queries'].present?
      puts "\n#### Import issue query\n\n"
      data['issue_queries'].each do |issue_query|
        import_issue_query issue_query, project
      end
    end
    if data.key?('time_entry_queries') && data['time_entry_queries'].present?
      puts "\n##### Import time entry query\n\n"
      data['time_entry_queries'].each do |time_entry_query|
        import_time_entry_query time_entry_query, project
      end
    end
    if data.key?('children') && data['children']
      data['children'].each do |child_identifier, child_data|
        import_project child_identifier, child_data, project
      end
    end
  end

  ## Wikiページのインポート
  def import_wiki_page(project, wiki_pages, parent=nil)
    wiki_pages.each do |page_name, data|
      wiki_page = project.wiki.find_or_new_page(page_name)
      wiki_page.parent_title = parent.title if parent
      content = wiki_page.content || WikiContent.new({page: wiki_page})
      content.text ||= "#{page_name}\n===========================\n\n{{child_pages}}"
      if data.instance_of?(String)
        content.text = data
      elsif data.instance_of?(Hash) && data['content']
        content.text = data['content']
      end
      content.author = User.find(ADMIN_USER_ID)
      wiki_page.save_with_content(content)
      wiki_page.save!
      puts "* " + wiki_page.title
      if data.instance_of?(Hash)
        # if data.key?('files') && data['files']
        #   import_attachment wiki_page, data
        # end
        if data.key?('children') && data['children']
          import_wiki_page project, data['children'], wiki_page
        end
      end
    end
  end

  ## チケットのカスタムクエリーのインポート
  def import_issue_query(data, project=nil)
    # TODO: 他のカスタムクエリの登録処理と共通処理を統合し最適化する必要あり
    # description/filters/columns/group_by/sortなど共通の処理が多いため、
    # この部分ではチケットクエリ固有のfiltersパラメーターの変換処理のみを行う形に変更し、
    # カスタムクエリの登録については別途定義した共通処理を呼び出す形にする
    issue_query = if data['id'].present?
      IssueQuery.find_or_initialize_by(id: data['id'])
    else
      project_id = project ? project.id : nil
      IssueQuery.find_or_initialize_by(name: data['name'], project_id: project_id)
    end
    if issue_query.new_record?
      # 表示：全てのユーザー
      issue_query.visibility = Query::VISIBILITY_PUBLIC
      # 全プロジェクト向け
      issue_query.project = project
      issue_query.user = User.find(ADMIN_USER_ID)
    end
    ## 名前
    issue_query.name = data['name']
    ## フィルター
    filter_fields = []
    filter_operators = {}
    filter_values = {}
    data['filters'].each do |key, value|
      field_name = key
      field_filter_operator = value['operator'] || value['op']
      field_filter_value = value['values'] || []
      case key
      when 'status'
        field_name = 'status_id'
        field_filter_value = IssueStatus.where(:name => field_filter_value).pluck(:id).map {|item| item.to_s }
      when 'tracker'
        field_name = 'tracker_id'
        field_filter_value = Tracker.where(:name => field_filter_value).pluck(:id).map {|item| item.to_s }
      when 'priority'
        field_name = 'priority_id'
        field_filter_value = IssuePriority.where(:name => field_filter_value).pluck(:id).map {|item| item.to_s }
      when 'author'
        field_name = 'author_id'
        has_me = field_filter_value.include?('me')
        field_filter_value = User.where(:login => field_filter_value).pluck(:id).map {|item| item.to_s }
        field_filter_value.push 'me' if has_me
      when 'assigned_to'
        field_name = 'assigned_to_id'
        has_me = field_filter_value.include?('me')
        field_filter_value = User.where(:login => field_filter_value).pluck(:id).map {|item| item.to_s }
        field_filter_value.push 'me' if has_me
      end
      filter_fields.push field_name
      filter_operators[field_name] = field_filter_operator
      filter_values[field_name] = field_filter_value
    end
    form_params = {
      c: [],
      sort: [
        ['id', 'desc']
      ]
    }
    ## フィルター
    form_params[:fields] = filter_fields
    form_params[:operators] = filter_operators
    form_params[:values] = filter_values
    ## 説明
    if data.key?('description') && data['columns'].present?
      form_params[:description] = data['description']
    end
    ## 表示項目
    if data.key?('columns') && data['columns'].present?
      form_params[:c] = data['columns']
    end
    ## 並び順
    if data.key?('sort') && data['sort'].present?
      form_params[:sort] = []
      data['sort'].each do |sort|
        form_params[:sort].push [sort['field'], sort['order']]
      end
    end
    ## グループ条件
    form_params[:group_by] = data['group_by'] if data.key?('group_by')
    ## 合計
    form_params[:t] = data['total'] if data.key?('total')
    issue_query.build_from_params form_params
    issue_query.save!
    puts "* #{issue_query.name}"
  end

  ## 時間管理のカスタムクエリーのインポート
  def import_time_entry_query(data, project=nil)
    # 時間管理（作業時間）のカスタムクエリをインポートします
    puts "未実装"
  end

  ## 添付ファイルのインポート
  def import_attachment(container, data)
    digest = Digest::SHA256.file(data['file']).to_s
    filename = File.basename(data['local_file'])
    if data.key?('filename') && data['filename'].present?
      filename = data['filename']
    end
    attachment_count = Attachment.where({container: container, filename: filename, digest: digest}).count
    if attachment_count == 0
      attachment = Attachment.new({container: container, author: User.find(ADMIN_USER_ID)})
      attachment.file = File.open(data['file'])
      attachment.filename = filename
      if data.key?('description') && data['description'].present?
        attachment.description = data['description']
      end
      attachment.save!
      puts({container_type: attachment.container_type, container_id: attachment.container_id, filename: attachment.filename})
    end
    FileUtils.rm_f(data['file']) unless ENV['IMPORT_DATA_FILE_NO_DELETE']
  end
end
