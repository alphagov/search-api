require "test_helper"
require "elasticsearch/amender"
require "search_config"

class AmenderTest < MiniTest::Unit::TestCase
  def setup
    @index = stubs('index')
  end

  def test_amend
    mock_document = mock("document") do
      expects(:has_field?).with("title").returns(true)
      expects(:set).with("title", "New title")
    end

    @index.expects(:get).with("/foobang").returns(mock_document)
    @index.expects(:add).with([mock_document])

    amend("/foobang", "title" => "New title")
  end

  def test_amend_with_link
    @index.expects(:get).with("/foobang").returns(mock("document"))
    @index.expects(:add).never

    assert_raises ArgumentError do
      amend("/foobang", "link" => "/flibble")
    end
  end

  def test_amend_with_bad_field
    mock_document = mock("document") do
      expects(:has_field?).with("fish").returns(false)
    end
    @index.expects(:get).with("/foobang").returns(mock_document)
    @index.expects(:add).never

    assert_raises ArgumentError do
      amend("/foobang", "fish" => "Trout")
    end
  end

  def test_amend_missing_document
    @index.expects(:get).with("/foobang").returns(nil)
    @index.expects(:add).never

    assert_raises Elasticsearch::DocumentNotFound do
      amend("/foobang", "title" => "New title")
    end
  end

  def amend(*args)
    Elasticsearch::Amender.new(@index).amend(*args)
  end
end
