require 'test_helper'

class GovukIndex::LicencePresenterTest < Minitest::Test
  def test_mapped_licence_fields
    details = {
      "continuation_link" => "http://www.on-and-on.com",
      "external_related_links" => [],
      "licence_identifier" => "1234-5-6",
      "licence_short_description" => "short description",
      "licence_overview" => [
        { "content_type" => "text/govspeak", "content" => "**overview**" },
        { "content_type" => "text/html", "content" => "<strong>overview</strong>" }
      ],
      "will_continue_on" => "on and on",
    }

    presenter = GovukIndex::LicencePresenter.new(details)

    assert_equal presenter.identifier, details["licence_identifier"]
    assert_equal presenter.short_description, details["licence_short_description"]
  end
end
