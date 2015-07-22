require "result_presenter"

class ResultSetPresenter
  def initialize(result_set, registries = {}, schema = nil)
    @result_set = result_set
    @registries = registries
    @schema = schema
  end

  def results
    @result_set.results.map do |document|
      ResultPresenter.new(document, @registries, @schema).present
    end
  end
end
