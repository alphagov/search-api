module Index
  class RemoteReindexer
    class MissingArguments < ArgumentError; end
    class ReindexFailed < StandardError; end

    def initialize(source_url:, dest_url:, index:, dest_client: nil, poll_interval: 10, out: $stdout)
      @source_url = source_url
      @dest_url = dest_url
      @index = index
      @dest_client = dest_client || Elasticsearch::Client.new(hosts: [dest_url])
      @poll_interval = poll_interval
      @out = out

      validate!
    end

    def reindex
      ensure_dest_index_exists!

      @out.puts "Reindexing #{@index} from #{@source_url} to #{@dest_url}"

      task_id = start_reindex

      @out.puts "Reindex started at #{Time.now}."
      @out.puts "Task_id: #{task_id}"

      poll_until_complete(task_id)
    end

  private

    def validate!
      return if @source_url && @dest_url && @index

      raise MissingArguments,
            "Usage: rake search:remote_reindex[https://source_url:443,https://dest_url:443, index]"
    end

    def ensure_dest_index_exists!
      return if @dest_client.indices.exists?(index: @index)

      raise "Destination index '#{@index}' does not exist"
    end

    def start_reindex
      response = @dest_client.reindex(
        body: {
          source: {
            remote: { host: @source_url },
            index: @index,
          },
          dest: { index: @index },
        },
        wait_for_completion: false,
      )

      response["task"]
    end

    def poll_until_complete(task_id)
      loop do
        task = @dest_client.tasks.get(task_id: task_id)

        if task["completed"]
          handle_completion(task)
          break
        end

        report_progress(task)
        sleep @poll_interval
      end
    end

    def handle_completion(task)
      raise ReindexFailed, "Reindex failed: #{task['error'].inspect}" if task["error"]

      result = task["response"]

      @out.puts "Reindex complete!"
      @out.puts "Created: #{result['created']}"
      @out.puts "Updated: #{result['updated']}"
      @out.puts "Failures: #{result['failures'].count}"
    end

    def report_progress(task)
      status = task.fetch("task").fetch("status")

      total = status["total"]
      processed = status["created"] + status["updated"] + status["deleted"]
      percent = total.zero? ? 0 : (processed.to_f / total * 100).round(1)

      @out.puts sprintf(
        "[%s] %d/%d documents (%.1f%%) | batches=%d | version_conflicts=%d",
        Time.now.strftime("%H:%M:%S"),
        processed,
        total,
        percent,
        status["batches"],
        status["version_conflicts"],
      )
    end
  end
end
