class SchemaMigrator
  def initialize(index_name, wait_between_task_list_check: 5)
    @index_name = index_name
    @wait_between_task_list_check = wait_between_task_list_check

    index_group.current.with_lock do
      yield(self)
    end
  end

  def reindex
    response = Services.elasticsearch(timeout: 60).reindex(
      wait_for_completion: false,
      body: {
        source: {
          index: index_group.current.real_name,
        },
        dest: {
          index: index.real_name,
          version_type: "external",
        }
      }
    )

    task_id = response.fetch('task')

    while running_tasks.include?(task_id)
      sleep @wait_between_task_list_check
    end
  end

  def changed?
    comparison[:changed] != 0
  end

  def switch_to_new_index
    index_group.switch_to(index)
  end

  def comparison
    @comparison ||= Indexer::Comparer.new(index_group.current.real_name, index.real_name).run
  end

private

  # this is awful but is caused by the return format of the tasks lists
  def running_tasks
    tasks = Services.elasticsearch.tasks.list(actions: '*reindex')
    nodes = tasks['nodes'] || {}
    node_details = nodes.values || []
    tasks = node_details.flat_map { |a| a['tasks'] }
    tasks.flat_map(&:keys)
  end

  def index_group
    @index_group ||= search_config.search_server.index_group(@index_name)
  end

  def index
    @index ||= index_group.create_index
  end
end
