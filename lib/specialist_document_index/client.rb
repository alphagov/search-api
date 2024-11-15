module SpecialistDocumentIndex
  class Client < Index::Client
  private

    def index_name
      # rubocop:disable Naming/MemoizedInstanceVariableName
      @_index ||= SearchConfig.specialist_document_index_name
      # rubocop:enable Naming/MemoizedInstanceVariableName
    end
  end
end
