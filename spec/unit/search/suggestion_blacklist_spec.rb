require 'spec_helper'

RSpec.describe 'Search::SuggestionBlacklistTest', tags: ['shoulda'] do
  def blacklist
    Search::SuggestionBlacklist.new(
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

    stub('organisation_registry', all: [mod_organisation])
  end

  context "#should_correct?" do
    it "correct normal strings" do
      assert blacklist.should_correct?("some test")
    end

    it "not correct strings with numbers" do
      refute blacklist.should_correct?("86asrdv")
    end

    it "not correct words added to ignore.yml" do
      refute blacklist.should_correct?("bodrum")
    end

    it "not correct names added to ignore.yml" do
      refute blacklist.should_correct?("Alan Turing")
    end

    it "correct words in the organization" do
      refute blacklist.should_correct?("mod")
    end
  end
end
