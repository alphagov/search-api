require "spec_helper"

RSpec.describe SpecialistDocumentIndex::PublishingEventProcessor do
  it "processes and acknowledges messages containing specialist documents" do
    payload = {
      "base_path" => "/cheese",
      "document_type" => "cma_case",
      "title" => "We love cheese",
    }
    message = double('message')
    expect(message).to receive('payload').and_return(payload)

    expect(SpecialistDocumentIndex::IndexSpecialistDocumentJob).to receive(:perform_async).with(payload)
    expect(message).to receive(:ack)

    subject.process(message)
  end

  it "processes and acknowledges messages containing unpublishing documents" do
    payload = {
      "base_path" => "/cheese",
      "document_type" => "gone",
    }
    message = double('message')
    expect(message).to receive('payload').and_return(payload)

    expect(SpecialistDocumentIndex::RemoveSpecialistDocumentJob).to receive(:perform_async).with(payload)
    expect(message).to receive(:ack)

    subject.process(message)
  end

  it "ignores and acknowledges messages not containing specialist documents" do
    payload = {
      "base_path" => "/cheese",
      "document_type" => "help_page",
      "title" => "We love cheese",
    }
    message = double('message')
    expect(message).to receive('payload').and_return(payload)

    expect(SpecialistDocumentIndex::IndexSpecialistDocumentJob).to_not receive(:perform_async).with(payload)
    expect(message).to receive(:ack)

    subject.process(message)
  end
end

