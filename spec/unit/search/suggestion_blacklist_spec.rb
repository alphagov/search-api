require 'spec_helper'

RSpec.describe Search::SuggestionBlacklist do
  def blacklist
    described_class.new(
      { organisations: stubbed_organisation_registry }
    )
  end

  def stubbed_organisation_registry
    mod_organisation = {
      "link" => "/government/organisations/ministry-of-defence",
      "title" => "Ministry of Defence",
      "acronym" => "MoD",
      "organisation_type" => "Ministerial department"
    }

    double('organisation_registry', all: [mod_organisation])
  end

  context "#should_correct?" do
    it "correct normal strings" do
      expect(blacklist.should_correct?("some test")).to be_truthy
    end

    it "not correct strings with numbers" do
      expect(blacklist.should_correct?("86asrdv")).to be_falsey
    end

    it "not correct words added to ignore.yml" do
      expect(blacklist.should_correct?("bodrum")).to be_falsey
    end

    it "not correct names added to ignore.yml" do
      expect(blacklist.should_correct?("Alan Turing")).to be_falsey
    end

    it "correct words in the organization" do
      expect(blacklist.should_correct?("mod")).to be_falsey
    end
  end
end
