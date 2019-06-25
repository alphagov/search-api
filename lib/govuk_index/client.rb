module GovukIndex
  class Client < Index::Client
  private

    def index_name
      @_index ||= SearchConfig.govuk_index_name
    end
  end
end
