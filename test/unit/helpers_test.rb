require "test_helper"
require "helpers"

class HelpersTest < MiniTest::Unit::TestCase
  include Helpers

  def test_simple_json_result_ok
    expects(:content_type).with(:json)
    # 200 is the default status: whether it gets called or not, we don't mind
    expects(:status).with(200).at_most_once
    assert_equal '{"result":"OK"}', simple_json_result(true)
  end

  def test_simple_json_result_error
    expects(:content_type).with(:json)
    expects(:status).with(500)
    assert_equal '{"result":"error"}', simple_json_result(false)
  end
end
