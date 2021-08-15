#{% raw %}
def import_issue_custom_filed(custom_fileds)
  custom_fileds.each do |item|
    next unless ALLOW_FIELD_FORMTS.include?(item['field_format'])
    cf = IssueCustomField.find_by_name(item['name'])
    cf = IssueCustomField.new unless cf
    # 形式
    cf.field_format = item['field_format']
    # 名称
    cf.name = item['name']
    # 説明
    cf.description = item['description'] if item.key?('description')
    # 必須
    cf.is_required = !!item['is_required'] if item.key?('is_required')
    # 最小値または最小文字列長
    if item.key?('min_length') && ALLOW_LENGTH_FORMATS.include?(item['field_format'])
      cf.min_length = item['min_length'].to_s
    end
    # 最大値値または最小文字列長
    if item.key?('max_length') && ALLOW_LENGTH_FORMATS.include?(item['field_format'])
      cf.max_length = item['max_length'].to_s
    end
    # 正規表現
    cf.regexp = item['regexp'] if item.key?('field_format') && ALLOW_REGEXP_FORMATS.include?(item['field_format'])
    # 初期値
    if item.key?('field_format') && ALLOW_DEFAULT_VALUE_FORMATS.include?(item['field_format'])
      cf.default_value = item['default_value'].to_s
    end
    # テキスト書式
    if item.key?('text_formatting') && ALLOW_TEXT_FORMATTING_FORMATS.include?(item['field_format'])
      cf.text_formatting = item['text_formatting'] ? true : false
    end
    # 値に設定するリンクURL
    if item.key?('url_pattern') && ALLOW_URL_PATTERN_FORMATS.include?(item['field_format'])
      cf.url_pattern = item['url_pattern']
    end
    # 表示(入力形式)
    if item.key?('edit_tag_style') && ALLOW_EDIT_TAG_STYLE_FORMATS.include?(item['field_format'])
      edit_tag_style = nil
      edit_tag_style = item['edit_tag_style'] if ['check_box', 'radio'].include?(item['edit_tag_style'])
      cf.edit_tag_style = edit_tag_style
    end
    # 複数選択
    if item.key?('multiple') && ALLOW_MULTIPLE_FORMATS.include?(item['field_format'])
      cf.multiple = item['multiple'] ? true : false
    end
    # 検索対象
    if item.key?('searchable') && ALLOW_SEARCHABLE_FORMATS.include?(item['field_format'])
      cf.searchable = item['searchable'] ? true : false
    end
    # 選択肢
    if item.key?('possible_values') && item['field_format'] == 'list'
      cf.possible_values = item['possible_values']
    end
    # ロール
    if item.key?('user_role') && item['field_format'] == 'user'
      cf.user_role = Role.where(:name => item['user_role']).pluck(:id).map {|v| v.to_s }
    end
    # ステータス
    if item.key?('version_status') && item['field_format'] == 'version'
      cf.version_status = item['version_status'].select { |v| ['open', 'locked', 'closed'].include?(v) }
    end
    # 許可する拡張子
    if item.key?('extensions_allowed') && item['field_format'] == 'attachment'
      extensions_allowed = item['extensions_allowed']
      extensions_allowed = item['extensions_allowed'].join(',') if item['extensions_allowed'].is_a?(Array)
      cf.extensions_allowed = extensions_allowed
    end
    # フィルタとして使用
    if item.key?('is_filter') && item['field_format'] != 'attachment'
      cf.is_filter = item['is_filter'] ? true : false
    end
    # 表示
    cf.visible = true
    if item.key?('visible')
       if item['visible'].is_a?(Array)
         cf.role_ids = Role.where(:name => item['visible']).pluck(:id).map {|v| v.to_s }
       else
         cf.visible = !!item['visible']
      end
    end
    # トラッカー
    if item.key?('trackers')
      cf.tracker_ids = Tracker.where(:name => item['trackers']).pluck(:id).map {|v| v.to_s }
    end
    # プロジェクト
    cf.is_for_all = true
    if item.key?('projects')
      cf.is_for_all = false
      cf.project_ids = Tracker.where(:name => item['projects']).pluck(:id).map {|v| v.to_s }
    end
    cf.save
  end
end

issue_custom_fileds = []
issue_custom_fileds = YAML.load_file('./tmp/import/issue_custom_field.yml') if File.exists?('./tmp/import/issue_custom_field.yml')

import_issue_custom_filed(issue_custom_fileds) if issue_custom_fileds.present?
#{% endraw %}

