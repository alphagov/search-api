require "spec_helper"

RSpec.describe LearnToRank::CtrToJudgements do
  subject(:instance) do
    described_class.new(
      results_and_ctrs.map do |query, results|
        {
          query => results.each_with_object({}).with_index do |(r, h), i|
            h[i.to_s] = r[:ctr]
          end
        }
      end, args
    )
  end

  let(:results_and_ctrs) {
    {
      "micropig" => [
        { ctr: 90, link: "/guidance/keeping-a-pet-pig-or-micropig" },
        { ctr: 5,  link: "/government/collections/guidance-for-keepers-of-sheep-goats-and-pigs" },
      ],
      "vehicle tax" => [
        { ctr: 5,  link: "/vehicle-tax" },
        { ctr: 20, link: "/check-vehicle-tax" },
        { ctr: 0,  link: "/make-a-sorn" },
        { ctr: 10, link: "/vehicle-tax-direct-debit" },
        { ctr: 0,  link: "/vehicle-tax-advance" },
        { ctr: 50, link: nil },
      ],
    }
  }

  let(:args) { {} }

  describe "#relevancy_judgements" do
    it "fetches search results from search-api" do
      stubs = stub_search_api(LearnToRank::CtrToJudgements::PUBLIC_SEARCH_API)
      instance.relevancy_judgements
      stubs.each { |stub| assert_requested(stub) }
    end

    it "gives relevancy judgements for each query" do
      stub_search_api(LearnToRank::CtrToJudgements::PUBLIC_SEARCH_API)
      judgements = instance.relevancy_judgements
      expected = results_and_ctrs.keys
      actual = judgements.map { |j| j[:query] }.uniq
      expect(expected.sort).to eq(actual.sort)
    end

    it "gives relevancy judgements on the 0 to 3 scale" do
      stub_search_api(LearnToRank::CtrToJudgements::PUBLIC_SEARCH_API)
      judgements = instance.relevancy_judgements
      judgements.each do |j|
        expect(j[:score]).to be_between(0, 3).inclusive
      end
    end
  end

  context "when a search-api URL is given" do
    let(:search_api_url) { "http://govuk.local" }
    let(:args) { { search_api: search_api_url } }

    describe "#relevancy_judgements" do
      it "fetches search results from the provided URL" do
        stubs = stub_search_api(search_api_url)
        instance.relevancy_judgements
        stubs.each { |stub| assert_requested(stub) }
      end
    end
  end

  def stub_search_api(search_api_url)
    results_and_ctrs.map do |query, results|
      stub_request(:get, "#{search_api_url}?fields=link&q=#{query}")
        .to_return(
          body: { results: results.map { |r| { link: r[:link] } }.compact }.to_json,
        )
    end
  end
end
