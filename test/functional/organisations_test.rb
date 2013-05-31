require "integration_test_helper"
require 'document_series_registry'
require "organisation_registry"
require "topic_registry"
require "world_location_registry"

class OrganisationsTest < IntegrationTest

  def mod_organisation
    Document.new(
      %w(link title acronym organisation_type),
      {
        link: "/government/organisations/ministry-of-defence",
        title: "Ministry of Defence",
        acronym: "MoD",
        organisation_type: "Ministerial department"
      }
    )
  end

  def test_returns_a_total
    OrganisationRegistry.any_instance.expects(:all).returns([mod_organisation])

    get "/organisations.json"

    parsed_response = MultiJson.decode(last_response.body)
    assert_equal 1, parsed_response["total"]
  end

  def test_returns_all_organisations
    OrganisationRegistry.any_instance.expects(:all).returns([mod_organisation])

    get "/organisations.json"

    parsed_response = MultiJson.decode(last_response.body)
    assert_equal 1, parsed_response["results"].size
    assert_equal mod_organisation.link, parsed_response["results"][0]["link"]
    assert_equal mod_organisation.title, parsed_response["results"][0]["title"]
    assert_equal mod_organisation.acronym, parsed_response["results"][0]["acronym"]
    assert_equal mod_organisation.organisation_type, parsed_response["results"][0]["organisation_type"]
    assert_equal "ministry-of-defence", parsed_response["results"][0]["slug"]
  end
end
