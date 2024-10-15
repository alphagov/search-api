module SpecialistFinderIndex
  class Client < Index::Client
  private

    def index_name
      # rubocop:disable Naming/MemoizedInstanceVariableName
      @_index ||= SearchConfig.govuk_index_name
      # rubocop:enable Naming/MemoizedInstanceVariableName
    end
  end
end
