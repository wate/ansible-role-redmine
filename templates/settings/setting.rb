#{% raw %}
def import_setting(setting)
  if setting.key?('default_projects_trackers')
    setting['default_projects_tracker_ids'] = Tracker.where(:name => setting['default_projects_trackers']).pluck(:id).map {|item| item.to_s }
    setting.delete('default_projects_trackers')
  end
  Setting.set_all_from_params(setting);
end

setting = {};
import_setting_file = File.join(REDMINE_IMPORT_FILE_DIR, 'setting.yml')
setting = YAML.load_file(import_setting_file) if File.exists?(import_setting_file)

import_setting(setting) if setting.present?
File.delete(import_setting_file) if File.exists?(import_setting_file)
#{% endraw %}
