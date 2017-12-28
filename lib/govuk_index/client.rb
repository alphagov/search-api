module GovukIndex
  class Client < Index::Client
  private

    def index_name
      @_index ||= search_config.govuk_index_name
    end
  end
end
