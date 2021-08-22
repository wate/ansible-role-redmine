#{% raw %}
def import_admin(admin)
  # 管理者
  default_admin = User.find_by_id(1)
  default_admin.login = admin['login'] if admin.key?('login')
  default_admin.firstname = admin['firstname'] if admin.key?('firstname')
  default_admin.lastname =  admin['lastname'] if admin.key?('lastname')
  default_admin.mail = admin['mail'] if admin.key?('mail')
  default_admin.language = admin['language'] if admin.key?('language')
  if admin.key?('password')
    default_admin.password = admin['password']
    default_admin.password_confirmation = admin['password']
    default_admin.must_change_passwd = admin['must_change_passwd']
  end
  default_admin.save
end
admin = {};
admin = YAML.load_file('./tmp/import/admin.yml') if File.exists?('./tmp/import/admin.yml')

import_admin(admin) if admin.present?
File.delete('./tmp/import/admin.yml') if File.exists?('./tmp/import/admin.yml')
#{% endraw %}
