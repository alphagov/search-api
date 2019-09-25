require "spec_helper"

RSpec.describe Helpers do
  subject do
    instance = double
    instance.extend(Helpers)
    instance
  end

  it "simple json result ok" do
    expect(subject).to receive(:content_type).with(:json)
    # 200 is the default status: whether it gets called or not, we don't mind
    expect(subject).to receive(:status).with(200).once
    expect(subject.simple_json_result(true)).to eq('{"result":"OK"}')
  end

  it "simple json result error" do
    expect(subject).to receive(:content_type).with(:json)
    expect(subject).to receive(:status).with(500)
    expect(subject.simple_json_result(false)).to eq('{"result":"error"}')
  end

  it "parse query string" do
    [
      ["foo=bar", { "foo" => %w[bar] }],
      ["foo[]=bar", { "foo" => %w[bar] }],
      ["foo=bar&foo[]=baz", { "foo" => %w(bar baz) }],
      ["foo=bar=baz", { "foo" => ["bar=baz"] }],
      ["foo[bar]=baz", { "foo[bar]" => %w[baz] }],
      ["foo[]=baz&q=more", { "foo" => %w[baz], "q" => %w[more] }],
      ["foo=baz&&q=more", { "foo" => %w[baz], "q" => %w[more] }],
      ["foo=baz&boo&q=more", { "foo" => %w[baz], "boo" => [], "q" => %w[more] }],
    ].each do |qs, expected|
      expect(subject.parse_query_string(qs)).to eq(expected)
    end
  end
end
