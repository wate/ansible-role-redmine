#{% raw %}
def import_group(groups)
  groups.each do |item|
    if item['id'].present?
      group = Group.find_by_id(item['id'])
      group.name = item['name']
    else
      group = Group.find_by_lastname(item['name'])
    end
    group = Group.new unless group
    group.name = item['name']
    if group.save
      if item['users'].present?
        users = User.not_in_group(group).where(:login => item['users']).to_a
        group.users << users
        end
    end
  end
end

groups = []
groups = YAML.load_file('./tmp/import/group.yml') if File.exists?('./tmp/import/group.yml')

import_group(groups) if groups.present?
File.delete('./tmp/import/group.yml') if File.exists?('./tmp/import/group.yml')
#{% endraw %}
