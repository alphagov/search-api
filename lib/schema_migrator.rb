class SchemaMigrator
  attr_accessor :failed

  def initialize(index_name, config, cluster: Clusters.default_cluster, wait_between_task_list_check: 5, io: STDOUT)
    @index_name = index_name
    @cluster = cluster
    @config = config
    @wait_between_task_list_check = wait_between_task_list_check
    @io = io
  end

  def reindex
    index_group.current.with_lock do
      response = Services.elasticsearch(cluster: cluster, timeout: 60).reindex(
        wait_for_completion: false,
        body: {
          source: {
            index: index_group.current.real_name,
          },
          dest: {
            index: index.real_name,
            version_type: "external",
          }
        },
        refresh: true
      )

      task_id = response.fetch('task')

      while running_tasks.include?(task_id)
        sleep @wait_between_task_list_check
      end

      if changed?
        puts "Difference during reindex for: #{index_name}"
        puts comparison.inspect
        @failed = true
      end
    end
  end

  def changed?
    comparison[:changed] != 0 ||
      comparison[:removed_items] != 0 ||
      comparison[:added_items] != 0
  end

  def switch_to_new_index
    index_group.switch_to(index)
  end

  def comparison
    @comparison ||= Indexer::Comparer.new(index_group.current.real_name, index.real_name, cluster: cluster, io: io).run
  end

private

  attr_reader :io, :cluster

  # this is awful but is caused by the return format of the tasks lists
  def running_tasks
    tasks = Services.elasticsearch(cluster: cluster).tasks.list(actions: '*reindex')
    nodes = tasks['nodes'] || {}
    node_details = nodes.values || []
    tasks = node_details.flat_map { |a| a['tasks'] }
    tasks.flat_map(&:keys)
  end

  def index_group
    @index_group ||= @config.search_server(cluster: cluster).index_group(@index_name)
  end

  def index
    @index ||= index_group.create_index
  end
end
