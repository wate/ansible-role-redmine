#{% raw %}
def import_time_entry_activity(time_entry_activities)
  time_entry_activities.each do |item|
    if item['id'].present?
      time_entry_activity = TimeEntryActivity.find_by_id(item['id'])
    else
      time_entry_activity = TimeEntryActivity.find_by_name(item['name'])
    end
    unless time_entry_activity
      time_entry_activity = TimeEntryActivity.new unless time_entry_activity
      time_entry_activity.active = true
    end
    time_entry_activity.name = item['name']
    time_entry_activity.active = !!item['active'] if item.key?('active')
    time_entry_activity.is_default = !!item['is_default'] if item.key?('is_default')
    time_entry_activity.position = item['position'] if item.key?('position')
    time_entry_activity.save
  end
end
time_entry_activities = []
time_entry_activities = YAML.load_file('./tmp/import/time_entry_activity.yml') if File.exists?('./tmp/import/time_entry_activity.yml')

import_time_entry_activity(time_entry_activities) if time_entry_activities.present?
File.delete('./tmp/import/time_entry_activity.yml') if File.exists?('./tmp/import/time_entry_activity.yml')
#{% endraw %}
