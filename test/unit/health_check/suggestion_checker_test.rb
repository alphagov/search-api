require 'test_helper'

module HealthCheck
  class SuggestionCheckerTest < ShouldaUnitTestCase
    context "result" do
      should "returns the correct calculator" do
        data = <<-doc
Search term,Ideal suggestion,Alternative suggestion
adress,address,
apprenteships,apprenticeships,
apprentiships,this is wrong,
nothing,,
other-thing,,
        doc

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

        result = HealthCheck::SuggestionChecker.new(
          search_client: HealthCheck::JsonSearchClient.new,
          test_data: StringIO.new(data)
        ).run!

        assert result.success_count == 3
        assert result.total_count == 5
      end
    end
  end
end
