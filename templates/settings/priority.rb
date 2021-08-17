#{% raw %}
def import_priority(priorities)
  priorities.each do |item|
    if item['id'].present?
      priority = IssuePriority.find_by_id(item['id'])
    else
      priority = IssuePriority.find_by_name(item['name'])
    end
    unless priority
      priority = IssuePriority.new
      priority.active = true
    end
    priority.name = item['name']
    priority.active = !!item['active'] if item.key?('active')
    priority.is_default = !!item['is_default'] if item.key?('is_default')
    priority.position = item['position'] if item.key?('position')
    priority.save
  end
end
priorities = []
priorities = YAML.load_file('./tmp/import/priority.yml') if File.exists?('./tmp/import/priority.yml')

import_priority(priorities) if priorities.present?
#{% endraw %}
