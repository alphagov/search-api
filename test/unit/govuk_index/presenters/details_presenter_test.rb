require 'test_helper'

class GovukIndex::DetailsPresenterTest < Minitest::Test
  def test_details_with_govspeak_and_text_html
    details = {
      "body" => [
        { "content_type" => "text/govspeak", "content" => "**hello**" },
        { "content_type" => "text/html", "content" => "<strong>hello</strong>" }
      ]
    }

    assert_equal "hello", details_presenter(details).indexable_content
  end

  def test_details_with_parts
    details = {
      "parts" => [
        {
          "title" => "title 1",
          "slug" => "title-1",
          "body" => [
            { "content_type" => "text/govspeak", "content" => "**hello**" },
            { "content_type" => "text/html", "content" => "<strong>hello</strong>" }
          ],
        },
        {
          "title" => "title 2",
          "slug" => "title-2",
          "body" => [
            { "content_type" => "text/govspeak", "content" => "**goodbye**" },
            { "content_type" => "text/html", "content" => "<strong>goodbye</strong>" }
          ],
        }
      ]
    }

    assert_equal "title 1\n\nhello\n\ntitle 2\n\ngoodbye", details_presenter(details).indexable_content
  end

  def test_licence_indexable_content
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

    assert_equal "short description\n\noverview", details_presenter(details).indexable_content
  end

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

    presenter = details_presenter(details)

    assert_equal presenter.licence_identifier, details["licence_identifier"]
    assert_equal presenter.licence_short_description, details["licence_short_description"]
  end

  def details_presenter(details)
    GovukIndex::DetailsPresenter.new(details)
  end
end
