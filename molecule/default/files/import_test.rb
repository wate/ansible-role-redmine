# frozen_string_literal: true

# 実運用のDB（production）とYAML元データを突き合わせて検証する
ENV['RAILS_ENV'] ||= 'production'
require File.expand_path('../../config/environment', __dir__)
require 'minitest/autorun'
require 'yaml'

IMPORT_DATA_DIR = ENV['IMPORT_DATA_DIR'] || File.join(Rails.root, 'tmp')

def load_import_yaml(name)
  path = File.join(IMPORT_DATA_DIR, "#{name}.yml")
  return [] unless File.exist?(path)
  YAML.safe_load(File.read(path))
end

class ImportTest < Minitest::Test
  # Status import tests
  def test_status_import_matches_yaml
    yaml = load_import_yaml('status')
    refute_empty yaml, 'status.yml is missing or empty'
    yaml.each do |data|
      status = IssueStatus.find_by(name: data['name'])
      assert status, "IssueStatus '#{data['name']}' not found"
      assert_equal data['position'], status.position if data['position']
      assert_equal data['id'], status.id if data['id']
    end
  end

  def test_tracker_import_matches_yaml
    yaml = load_import_yaml('tracker')
    refute_empty yaml, 'tracker.yml is missing or empty'
    yaml.each do |data|
      tracker = Tracker.find_by(name: data['name'])
      assert tracker, "Tracker '#{data['name']}' not found"
      assert_equal data['position'], tracker.position if data['position']
      if data.key?('is_in_roadmap')
        assert_equal !!data['is_in_roadmap'], tracker.is_in_roadmap
      end
    end
  end

  def test_role_import_matches_yaml
    yaml = load_import_yaml('role')
    refute_empty yaml, 'role.yml is missing or empty'
    yaml.each do |data|
      role = Role.find_by(name: data['name'])
      assert role, "Role '#{data['name']}' not found"
      if data['permissions']
        expected = data['permissions'].map(&:to_sym)
        expected.each do |perm|
          assert_includes role.permissions, perm, "Role '#{data['name']}' missing permission '#{perm}'"
        end
      end
    end
  end

  def test_priority_import_matches_yaml
    yaml = load_import_yaml('priority')
    refute_empty yaml, 'priority.yml is missing or empty'
    yaml.each do |data|
      p = IssuePriority.find_by(name: data['name'])
      assert p, "IssuePriority '#{data['name']}' not found"
      assert_equal !!data['is_default'], p.is_default if data.key?('is_default')
    end
  end

  def test_document_category_import_matches_yaml
    yaml = load_import_yaml('document_category')
    refute_empty yaml, 'document_category.yml is missing or empty'
    yaml.each do |data|
      c = DocumentCategory.find_by(name: data['name'])
      assert c, "DocumentCategory '#{data['name']}' not found"
    end
  end

  def test_time_entry_activity_import_matches_yaml
    yaml = load_import_yaml('time_entry_activity')
    refute_empty yaml, 'time_entry_activity.yml is missing or empty'
    yaml.each do |data|
      a = TimeEntryActivity.find_by(name: data['name'])
      assert a, "TimeEntryActivity '#{data['name']}' not found"
      assert_equal data['position'], a.position if data['position']
    end
  end

  def test_issue_custom_field_import_matches_yaml
    yaml = load_import_yaml('issue_custom_field')
    refute_empty yaml, 'issue_custom_field.yml is missing or empty'
    yaml.each do |data|
      cf = IssueCustomField.find_by(name: data['name'])
      assert cf, "IssueCustomField '#{data['name']}' not found"
      assert_equal data['field_format'], cf.field_format
    end
  end

  def test_project_custom_field_import_matches_yaml
    yaml = load_import_yaml('project_custom_field')
    refute_empty yaml, 'project_custom_field.yml is missing or empty'
    yaml.each do |data|
      cf = ProjectCustomField.find_by(name: data['name'])
      assert cf, "ProjectCustomField '#{data['name']}' not found"
      assert_equal data['field_format'], cf.field_format
    end
  end

  def test_user_custom_field_import_matches_yaml
    yaml = load_import_yaml('user_custom_field')
    refute_empty yaml, 'user_custom_field.yml is missing or empty'
    yaml.each do |data|
      cf = UserCustomField.find_by(name: data['name'])
      assert cf, "UserCustomField '#{data['name']}' not found"
      assert_equal data['field_format'], cf.field_format
    end
  end

  def test_user_import_matches_yaml
    yaml = load_import_yaml('user')
    refute_empty yaml, 'user.yml is missing or empty'
    yaml.each do |login, data|
      u = User.find_by(login: login)
      assert u, "User '#{login}' not found"
      assert_equal data['mail'], u.mail if data['mail']
      assert_equal data['firstname'], u.firstname if data['firstname']
      assert_equal data['lastname'], u.lastname if data['lastname']
    end
  end

  def test_group_import_matches_yaml
    yaml = load_import_yaml('group')
    refute_empty yaml, 'group.yml is missing or empty'
    yaml.each do |data|
      g = Group.find_by(lastname: data['name'] || data['lastname'])
      assert g, "Group '#{data['name'] || data['lastname']}' not found"
    end
  end

  def test_project_import_matches_yaml
    yaml = load_import_yaml('project')
    refute_empty yaml, 'project.yml is missing or empty'
    yaml.each do |identifier, data|
      p = Project.find_by(identifier: identifier)
      assert p, "Project '#{identifier}' not found"
      assert_equal data['name'] || identifier, p.name
    end
  end

  # Workflow import tests (YAML)
  def test_workflow_import_matches_yaml
    yaml = load_import_yaml('workflow')
    refute_empty yaml, 'workflow.yml is missing or empty'
    yaml.each do |data|
      roles = Array(data['roles'])
      trackers = Array(data['trackers'])
      transitions = Array(data['transitions'])
      refute_empty roles
      refute_empty trackers
      refute_empty transitions
      roles.each do |role_name|
        role = Role.find_by(name: role_name)
        assert role, "Role '#{role_name}' not found"
        trackers.each do |tracker_name|
          tracker = Tracker.find_by(name: tracker_name)
          assert tracker, "Tracker '#{tracker_name}' not found"
          transitions.each do |tr|
            to_statuses = IssueStatus.where(name: Array(tr['to']))
            to_statuses.each do |to_status|
              exists = WorkflowTransition.where(role_id: role.id, tracker_id: tracker.id, new_status_id: to_status.id).exists?
              assert exists, "Workflow transition to '#{to_status.name}' missing for role '#{role_name}' and tracker '#{tracker_name}'"
            end
          end
        end
      end
    end
  end

  # Setting import tests (YAML)
  def test_setting_import_matches_yaml
    yaml = load_import_yaml('setting')
    refute_empty yaml, 'setting.yml is missing or empty'
    core = yaml.reject { |k, _| k.start_with?('plugin_') }
    # Core known keys if present in YAML
    {
      'text_formatting' => ->(v) { assert_equal v, Setting.text_formatting },
      'default_language' => ->(v) { assert_equal v, Setting.default_language },
      'user_format' => ->(v) { assert_equal v, Setting.user_format.to_s },
      'login_required' => ->(v) { assert_equal !!v, Setting.login_required? },
      'rest_api_enabled' => ->(v) { assert_equal !!v, Setting.rest_api_enabled? },
      'default_projects_public' => ->(v) {
        expected = (v == true || v.to_s == '1')
        assert_equal expected, Setting.default_projects_public?
      }
    }.each do |key, checker|
      checker.call(core[key]) if core.key?(key)
    end
    # Plugin settings: assert presence if provided
    # (Note: Exact value comparison skipped as plugin settings may have different serialization)
    plugin = yaml.select { |k, _| k.start_with?('plugin_') }
    plugin.each do |key, value|
      stored = Setting[key]
      assert stored, "Plugin setting '#{key}' not found"
    end
  end

  # Issue Query import tests (YAML)
  def test_issue_query_import_matches_yaml
    yaml = load_import_yaml('issue_query')
    refute_empty yaml, 'issue_query.yml is missing or empty'
    yaml.each do |data|
      q = IssueQuery.find_by(name: data['name'])
      assert q, "IssueQuery '#{data['name']}' not found"
      if data['filters']
        assert q.filters && !q.filters.empty?, "IssueQuery '#{data['name']}' has no filters after import"
      end
    end
  end

  # Project Query import tests (YAML)
  def test_project_query_import_matches_yaml
    yaml = load_import_yaml('project_query')
    refute_empty yaml, 'project_query.yml is missing or empty'
    yaml.each do |data|
      q = ProjectQuery.find_by(name: data['name'])
      assert q, "ProjectQuery '#{data['name']}' not found"
      if data['visibility']
        expected_visibility = data['visibility'] ? Query::VISIBILITY_PUBLIC : Query::VISIBILITY_PRIVATE
        assert_equal expected_visibility, q.visibility
      end
    end
  end

  # Time Entry Query import tests (YAML)
  def test_time_entry_query_import_matches_yaml
    yaml = load_import_yaml('time_entry_query')
    if yaml.nil? || yaml.empty?
      skip 'time_entry_query.yml not provided; skipping time entry query tests'
    else
      yaml.each do |data|
        q = TimeEntryQuery.find_by(name: data['name'])
        assert q, "TimeEntryQuery '#{data['name']}' not found"
        if data['filters']
          assert q.filters && !q.filters.empty?, "TimeEntryQuery '#{data['name']}' has no filters after import"
        end
      end
    end
  end

  # Attachment import tests (YAML)
  def test_attachment_import_matches_yaml
    yaml = load_import_yaml('attachment')
    refute_empty yaml, 'attachment.yml is missing or empty'
    yaml.each do |data|
      filename = data['filename'] || File.basename(data['local_file'].to_s)
      assert filename && !filename.empty?, 'Attachment filename missing in YAML'
      att = Attachment.find_by(filename: filename)
      assert att, "Attachment '#{filename}' not found"
    end
  end
end
