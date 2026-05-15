class SchemaMigrator
  attr_accessor :failed

  def initialize(index_name, cluster: Clusters.default_cluster, wait_between_task_list_check: 5, io: $stdout)
    @index_name = index_name
    @cluster = cluster
    @wait_between_task_list_check = wait_between_task_list_check
    @io = io
  end

  def dest_index
    @dest_index ||= index_group.create_index
  end

  def reindex
    index_group.current.with_lock do
      response = Services.elasticsearch(hosts: "#{cluster.uri}?slices=auto", timeout: TIMEOUT_SECONDS).reindex(
        wait_for_completion: false,
        body: {
          source: {
            index: index_group.current.real_name,
          },
          dest: {
            index: dest_index.real_name,
            version_type: "external",
          },
        },
        refresh: true,
      )

      task_id = response.fetch("task")

      sleep @wait_between_task_list_check while running_tasks.include?(task_id)

      @failed = get_task(task_id)["error"].present?
    end
  end

  def switch_to_new_index
    index_group.switch_to(@dest_index)
  end

private

  TIMEOUT_SECONDS = 60

  attr_reader :io, :cluster

  # this is awful but is caused by the return format of the tasks lists
  def running_tasks
    tasks = Services.elasticsearch(cluster:, retry_on_failure: 20, timeout: TIMEOUT_SECONDS).tasks.list(actions: "*reindex")
    nodes = tasks["nodes"] || {}
    node_details = nodes.values || []
    tasks = node_details.flat_map { |a| a["tasks"] }
    tasks.flat_map(&:keys)
  end

  def get_task(task_id)
    Services.elasticsearch(cluster:, retry_on_failure: 20, timeout: TIMEOUT_SECONDS).tasks.get(task_id: task_id)
  end

  def index_group
    @index_group ||= SearchConfig.instance(cluster).search_server.index_group(@index_name)
  end
end
