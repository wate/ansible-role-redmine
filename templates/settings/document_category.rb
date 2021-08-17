#{% raw %}
def import_document_category(document_categories)
  document_categories.each do |item|
    if item['id'].present?
      document_category = DocumentCategory.find_by_id(item['id'])
    else
      document_category = DocumentCategory.find_by_name(item['name'])
    end
    unless document_category
      document_category = DocumentCategory.new unless document_category
      document_category.active = true
    end
    document_category.name = item['name']
    document_category.active = !!item['active'] if item.key?('active')
    document_category.is_default = !!item['is_default'] if item.key?('is_default')
    document_category.position = item['position'] if item.key?('position')
    document_category.save
  end
end
document_categories = []
document_categories = YAML.load_file('./tmp/import/document_category.yml') if File.exists?('./tmp/import/document_category.yml')

import_document_category(document_categories) if document_categories.present?
#{% endraw %}
