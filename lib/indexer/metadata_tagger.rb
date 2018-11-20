module Indexer
  class MetadataTagger
    def self.amend_indexes_for_file(file_name)
      file = File.read(file_name)
      json = JSON.parse(file)

      # the key is our base path, the value a hash of metadata to amend
      # base_path: { key: value, key: value }
      json.each do |base_path, metadata|
        item_in_search = SearchConfig.instance.content_index.get_document_by_link(base_path)
        index_to_update = item_in_search["real_index_name"]
        Indexer::AmendWorker.new.perform(index_to_update, base_path, metadata)
      end
    end
  end
end
