require "spec_helper"

RSpec.describe Search::SuggestionBlocklist do
  context "with an organisation registry" do
    def blocklist
      described_class.new(
        { organisations: stubbed_organisation_registry },
      )
    end

    def stubbed_organisation_registry
      mod_organisation = {
        "link" => "/government/organisations/ministry-of-defence",
        "title" => "Ministry of Defence",
        "acronym" => "MoD",
        "organisation_type" => "Ministerial department",
      }

      instance_double("BaseRegistry", "organisation_registry", all: [mod_organisation])
    end

    it "correct normal strings" do
      expect(blocklist).to be_should_correct("some test")
    end

    it "not correct strings with numbers" do
      expect(blocklist).not_to be_should_correct("86asrdv")
    end

    it "not correct words added to ignore.yml" do
      expect(blocklist).not_to be_should_correct("bodrum")
    end

    it "not correct names added to ignore.yml" do
      expect(blocklist).not_to be_should_correct("Alan Turing")
    end

    it "correct words in the organization" do
      expect(blocklist).not_to be_should_correct("mod")
    end
  end
end
