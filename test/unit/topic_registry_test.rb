require "test_helper"
require "document"
require "topic_registry"

class TopicRegistryTest < MiniTest::Unit::TestCase
  def setup
    @index = stub("elasticsearch index")
    @topic_registry = TopicRegistry.new(@index)
  end

  def housing_document
    Document.new(
      %w(slug link title),
      {
        slug: "housing",
        link: "/government/topics/housing",
        title: "Housing"
      }
    )
  end

  def test_uses_Time_as_default_clock
    # This is to make sure the cache expiry is expressed in seconds; DateTime,
    # for example, treats number addition as a number of days.
    TimedCache.expects(:new).with(is_a(Fixnum), Time)
    TopicRegistry.new(stub("index"))
  end

  def test_can_fetch_topic_by_slug
    @index.stubs(:documents_by_format)
      .with("topic", anything)
      .returns([housing_document])
    topic = @topic_registry["housing"]
    assert_equal "housing", topic.slug
    assert_equal "/government/topics/housing", topic.link
    assert_equal "Housing", topic.title
  end

  def test_can_fall_back_on_link_munging
    # TODO: remove this once all the slugs are migrated
    housing_document_without_slug = Document.new(
      %w(slug link title),
      {
        link: "/government/topics/housing",
        title: "Housing"
      }
    )
    @index.stubs(:documents_by_format)
      .with("topic", anything)
      .returns([housing_document_without_slug])
    topic = @topic_registry["housing"]
    assert_equal "/government/topics/housing", topic.link
    assert_equal "Housing", topic.title
  end

  def test_only_required_fields_are_requested_from_index
    @index.expects(:documents_by_format)
      .with("topic", fields: %w{slug link title})
    topic = @topic_registry["housing"]
  end

  def test_returns_nil_if_topic_not_found
    @index.stubs(:documents_by_format)
      .with("topic", anything)
      .returns([housing_document])
    topic = @topic_registry["the-war"]
    assert_nil topic
  end

  def test_document_enumerator_is_traversed_only_once
    document_enumerator = stub("enumerator")
    document_enumerator.expects(:to_a).returns([housing_document]).once
    @index.stubs(:documents_by_format)
      .with("topic", anything)
      .returns(document_enumerator)
      .once
    assert @topic_registry["housing"]
    assert @topic_registry["housing"]
  end

  def test_uses_cache
    # Make sure we're using TimedCache#get; TimedCache is tested elsewhere, so
    # we don't need to worry about cache expiry tests here.
    TimedCache.any_instance.expects(:get).with().returns([housing_document])
    assert @topic_registry["housing"]
  end
end
