#{% raw %}
def import_setting(setting)
  if setting.key?('default_projects_trackers')
    setting['default_projects_tracker_ids'] = Tracker.where(:name => setting['default_projects_trackers']).pluck(:id).map {|item| item.to_s }
    setting.delete('default_projects_trackers')
  end
  Setting.set_all_from_params(setting);
end

setting = {};
setting = YAML.load_file('./tmp/import/setting.yml') if File.exists?('./tmp/import/setting.yml')

import_setting(setting) if setting.present?
File.delete('./tmp/import/setting.yml') if File.exists?('./tmp/import/setting.yml')
#{% endraw %}
