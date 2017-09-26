require 'spec_helper'

RSpec.describe HealthCheck::SuggestionChecker, tags: ['shoulda'] do
  context "result" do
    it "returns the correct calculator" do
      data = <<~DOC
        Search term,Ideal suggestion,Alternative suggestion
        adress,address,
        apprenteships,apprenticeships,
        apprentiships,this is wrong,
        nothing,,
        other-thing,,
      DOC

      responses = {
        'adress' => ['address'],
        'apprentiships' => ['apprenticeships'],
        'apprenteships' => ['apprenticeships'],
        'nothing' => [],
        'other-thing' => ['something']
      }

      responses.each do |term, suggestions|
        stub_request(:get, "https://www.gov.uk/api/search.json?count=0&q=#{term}&suggest=spelling").
          to_return(body: JSON.dump(results: [], suggested_queries: suggestions))
      end

      result = described_class.new(
        search_client: HealthCheck::JsonSearchClient.new,
        test_data: StringIO.new(data)
      ).run!

      assert result.success_count == 3
      assert result.total_count == 5
    end
  end
end
