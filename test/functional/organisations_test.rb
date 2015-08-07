require "integration_test_helper"
require "registry"

class OrganisationsTest < IntegrationTest

  def setup
    super
    stub_elasticsearch_settings
  end

  def mod_organisation
    Document.new(
      sample_field_definitions(%w(link title acronym organisation_type)),
      {
        link: "/government/organisations/ministry-of-defence",
        title: "Ministry of Defence",
        acronym: "MoD",
        organisation_type: "Ministerial department"
      }
    )
  end

  def test_returns_a_total
    Registry::Organisation.any_instance.expects(:all).returns([mod_organisation])

    get "/organisations.json"

    assert_equal 1, parsed_response["total"]
  end

  def test_returns_all_organisations
    Registry::Organisation.any_instance.expects(:all).returns([mod_organisation])

    get "/organisations.json"

    assert_equal 1, parsed_response["results"].size
    assert_equal mod_organisation.link, parsed_response["results"][0]["link"]
    assert_equal mod_organisation.title, parsed_response["results"][0]["title"]
    assert_equal mod_organisation.acronym, parsed_response["results"][0]["acronym"]
    assert_equal mod_organisation.organisation_type, parsed_response["results"][0]["organisation_type"]
    assert_equal "ministry-of-defence", parsed_response["results"][0]["slug"]
  end
end
