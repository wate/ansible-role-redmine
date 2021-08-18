#{% raw %}
def import_workflow(workflows)
  all_statuses = IssueStatus.all
  workflows.each do |item|
    # puts '---------------------------'
    roles = Role.where(:name =>  item['roles']).to_a
    trackers = Tracker.where(:name =>  item['trackers']).to_a

    transitions = {}
    status_ids = all_statuses.pluck(:id).map {|item| item.to_s }
    status_ids.prepend '0'
    status_ids.each do |status_id|
      all_statuses.each do |status|
        transitions[status_id] = {} unless transitions.key?(status_id)
        transitions[status_id][status.id.to_s] = {'always' => false, 'author' => false, 'assignee' => false}
      end
    end
    # puts YAML.dump(transitions)
    item['transitions'].each do |transition|
      from_status_id = '0'
      if transition['from']
        from_status = IssueStatus.find_by_name(transition['from'])
        from_status_id = from_status.id.to_s
      end
      to_statuses = IssueStatus.where(:name => transition['to'])
      to_statuses.each do |to_status|
        to_status_id = to_status.id.to_s
        # puts transition['from'].to_s + '(' + from_status_id + ') => ' + to_status.name + '(' + to_status_id + ')'
        transitions[from_status_id][to_status_id]['always'] = true
      end
    end
    # puts YAML.dump(transitions)
    WorkflowTransition.replace_transitions(trackers, roles, transitions)
  end
end

workflows = [];
workflows = YAML.load_file('./tmp/import/workflow.yml') if File.exists?('./tmp/import/workflow.yml')

import_workflow(workflows) if workflows.present?
File.delete('./tmp/import/workflow.yml') if File.exists?('./tmp/import/workflow.yml')
#{% endraw %}
