#{% raw %}
def import_message_customize(setting)
  if Redmine::Plugin.installed? :redmine_message_customize
    plugin_setting = CustomMessageSetting.find_or_default
    plugin_setting.update_with_custom_messages_yaml(setting)
  end
end
setting = ''
setting = File.read('./tmp/import/message_customize.yml') if File.exists?('./tmp/import/message_customize.yml')

puts setting

import_message_customize(setting) if setting != '{}'
File.delete('./tmp/import/message_customize.yml') if File.exists?('./tmp/import/message_customize.yml')
#{% endraw %}
