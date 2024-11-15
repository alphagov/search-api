require "spec_helper"
require "rake"
load "tasks/message_queue.rake"

RSpec.describe Indexer::MessageProcessor, "RakeTest" do
  context "when indexing published documents to publishing-api" do
    it "use GovukMessageQueueConsumer::Consumer" do
      indexer = described_class.new
      expect(described_class).to receive(:new).and_return(indexer)

      consumer = double("consumer")
      expect(consumer).to receive(:run).and_return(true)

      expect(GovukMessageQueueConsumer::Consumer).to receive(:new)
        .with(
          queue_name: "search_api_to_be_indexed",
          processor: indexer,
        ).and_return(consumer)

      Rake::Task["message_queue:listen_to_publishing_queue"].invoke
    end
  end
end

RSpec.describe SpecialistDocumentIndex::PublishingEventProcessor, "RakeTest" do
  context "when indexing specialist documents published via Publishing API" do
    it "use SpecialistDocumentMessageQueueConsumer::Consumer" do
      indexer = described_class.new
      expect(described_class).to receive(:new).and_return(indexer)

      consumer = double("consumer")
      expect(consumer).to receive(:run).and_return(true)

      expect(GovukMessageQueueConsumer::Consumer).to receive(:new)
                                                       .with(
                                                         queue_name: "search_api_specialist_document_index",
                                                         processor: indexer,
                                                         ).and_return(consumer)

      Rake::Task["message_queue:insert_data_into_specialist_document_index"].invoke
    end
  end
end
