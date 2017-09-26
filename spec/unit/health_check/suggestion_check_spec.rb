require 'spec_helper'
Logging.logger.root.appenders = nil

RSpec.describe HealthCheck::SuggestionCheck do
  context "#success?" do
    it "be true when the result and query match" do
      check = described_class.new(expected_result: 'x', suggested_query: 'x')

      assert check.success?
    end

    it "be false when the result and query do not match" do
      check = described_class.new(expected_result: 'A', suggested_query: 'B')

      refute check.success?
    end

    it "accept lowercase expected results" do
      check = described_class.new(expected_result: 'A', suggested_query: 'a')

      assert check.success?
    end

    it "accept empty results" do
      check = described_class.new(expected_result: '', suggested_query: nil)

      assert check.success?
    end
  end
end
