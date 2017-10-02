require 'spec_helper'

RSpec.describe Search::ResultPresenter, 'Temporary Link Fix' do
  it "appending_a_slash_to_the_link_field" do
    document = {
      '_type' => 'raib_report',
      '_index' => 'mainstream_test',
      'fields' => { 'link' => ['some/link'] }
    }

    result = described_class.new(document, nil, sample_schema, Search::QueryParameters.new(return_fields: %w[link])).present

    expect(result["link"]).to eq("/some/link")
  end

  it "keep_http_links_intact" do
    document = {
      '_type' => 'raib_report',
      '_index' => 'mainstream_test',
      'fields' => { 'link' => ['http://example.org/some-link'] }
    }

    result = described_class.new(document, nil, sample_schema, Search::QueryParameters.new(return_fields: %w[link])).present

    expect(result["link"]).to eq("http://example.org/some-link")
  end

  it "keep_correct_links_intact" do
    document = {
      '_type' => 'raib_report',
      '_index' => 'mainstream_test',
      'fields' => { 'link' => ['/some-link'] }
    }

    result = described_class.new(document, nil, sample_schema, Search::QueryParameters.new(return_fields: %w[link])).present

    expect(result["link"]).to eq("/some-link")
  end
end
