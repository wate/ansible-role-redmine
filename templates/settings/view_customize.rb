#{% raw %}
def import_view_customize(settings)
  if Redmine::Plugin.installed? :view_customize
    settings.each do |item|
      if item['id'].present?
        view_customize = ViewCustomize.find_by_id(item['id'])
      else
        view_customize = ViewCustomize.find_by_comments(item['name'])
      end
      unless view_customize
        data = item
        data['comments'] = item['name']
        data.delete('name')
        view_customize = ViewCustomize.new(data)
      end
      view_customize.code = item['code']
      view_customize.path_pattern = item['path_pattern'] if item.key?('path_pattern')
      view_customize.project_pattern = item['project_pattern'] if item.key?('project_pattern')
      view_customize.insertion_position = item['insertion_position'] if item.key?('insertion_position')
      view_customize.customize_type = item['customize_type'] if item.key?('customize_type')
      view_customize.is_enabled = !!item['is_enabled']  if item.key?('is_enabled')
      view_customize.save
    end
  end
end
settings = []
settings = YAML.load_file('./tmp/import/view_customize.yml') if File.exists?('./tmp/import/view_customize.yml')

import_view_customize(settings) if settings.present?
File.delete('./tmp/import/view_customize.yml') if File.exists?('./tmp/import/view_customize.yml')
#{% endraw %}
