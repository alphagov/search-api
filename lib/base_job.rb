class BaseJob
  include Sidekiq::Job

  # How long to wait, by default, if the index is currently locked
  LOCK_DELAY = 60 # seconds

  # Default options: can be overridden with `sidekiq_options` in subclasses
  sidekiq_options retry: 5, backtrace: 12

  def self.notify_of_failures
    sidekiq_retries_exhausted do |msg|
      GovukError.notify(Indexer::FailedJobException.new, extra: msg)
    end
  end

private

  def indexes(index_name)
    SearchConfig.search_servers.map do |search_server|
      search_server.index(index_name)
    end
  end
end
