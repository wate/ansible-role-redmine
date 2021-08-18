#{% raw %}
def import_status(statuses)
  statuses.each do |item|
    if item['id'].present?
      status = IssueStatus.find_by_id(item['id'])
      status.name = item['name']
    else
      status = IssueStatus.find_by_name(item['name'])
    end
    status = IssueStatus.new unless status
    status.safe_attributes = item
    status.position = item['position'] if item['position'].present?
    status.save
  end
end

statuses = []
statuses = YAML.load_file('./tmp/import/status.yml') if File.exists?('./tmp/import/status.yml')

import_status(statuses) if statuses.present?
File.delete('./tmp/import/status.yml') if File.exists?('./tmp/import/status.yml')
#{% endraw %}
