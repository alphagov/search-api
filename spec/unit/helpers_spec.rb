require 'spec_helper'

RSpec.describe 'HelpersTest' do
  include Helpers

  it "simple_json_result_ok" do
    expects(:content_type).with(:json)
    # 200 is the default status: whether it gets called or not, we don't mind
    expects(:status).with(200).at_most_once
    assert_equal '{"result":"OK"}', simple_json_result(true)
  end

  it "simple_json_result_error" do
    expects(:content_type).with(:json)
    expects(:status).with(500)
    assert_equal '{"result":"error"}', simple_json_result(false)
  end

  it "parse_query_string" do
    [
      ["foo=bar", { "foo" => ["bar"] }],
      ["foo[]=bar", { "foo" => ["bar"] }],
      ["foo=bar&foo[]=baz", { "foo" => %w(bar baz) }],
      ["foo=bar=baz", { "foo" => ["bar=baz"] }],
      ["foo[bar]=baz", { "foo[bar]" => ["baz"] }],
      ["foo[]=baz&q=more", { "foo" => ["baz"], "q" => ["more"] }],
      ["foo=baz&&q=more", { "foo" => ["baz"], "q" => ["more"] }],
      ["foo=baz&boo&q=more", { "foo" => ["baz"], "boo" => [], "q" => ["more"] }],
    ].each do |qs, expected|
      assert_equal expected, parse_query_string(qs)
    end
  end
end
