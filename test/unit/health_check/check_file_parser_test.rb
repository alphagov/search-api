require_relative "../../test_helper"
require "health_check/check_file_parser"

module HealthCheck
  class CheckFileParserTest < ShouldaUnitTestCase

    def checks(data)
      CheckFileParser.new(StringIO.new(data)).checks
    end

    should "read the supplied file and return a list of checks" do
      data = """Monthly searches,When I search for...,Then I...,see...,in the top ... results
600,a,should,https://www.gov.uk/a,1
500,b,should,https://www.gov.uk/b,1
"""
      expected = [Check.new("a", "should", "/a", 1, 600), Check.new("b", "should", "/b", 1, 500)]
      assert_equal expected, checks(data)
    end

    should "skip rows that don't have an integer for the top N number" do
      data = """Monthly searches,When I search for...,Then I...,see...,in the top ... results
500,b,should,https://www.gov.uk/b,mistake
"""
      expected = []
      assert_equal expected, checks(data)
    end

    should "accept Monthly searches values containing commas" do
      data = """Monthly searches,When I search for...,Then I...,see...,in the top ... results
\"6,000\",a,should,https://www.gov.uk/a,1
"""
      expected = [Check.new("a", "should", "/a", 1, 6_000)]
      assert_equal expected, checks(data)
    end

    should "skip rows that don't have an integer for Monthly searches" do
      data = """Monthly searches,When I search for...,Then I...,see...,in the top ... results
mistake,a,should,https://www.gov.uk/a,1
"""
      expected = []
      assert_equal expected, checks(data)
    end

    should "default weight to 1 for rows with blank Monthly searches" do
      data = """Monthly searches,When I search for...,Then I...,see...,in the top ... results
,a,should,https://www.gov.uk/a,1
"""
      expected = [Check.new("a", "should", "/a", 1, 1)]
      assert_equal expected, checks(data)
    end

    should "skip rows that don't have a URL" do
      data = """Monthly searches,When I search for...,Then I...,see...,in the top ... results
600,a,should,mistake,1
"""
      expected = []
      assert_equal expected, checks(data)
    end

    should "skip rows that don't have a imperative" do
      data = """Monthly searches,When I search for...,Then I...,see...,in the top ... results
600,a,,https://www.gov.uk/a,1
"""
      expected = []
      assert_equal expected, checks(data)
    end

    should "skip rows that don't have a search term" do
      data = """Monthly searches,When I search for...,Then I...,see...,in the top ... results
600,,should,https://www.gov.uk/a,1
"""
      expected = []
      assert_equal expected, checks(data)
    end

    should "skip checks with a Monthly searches of zero" do
      data = """Monthly searches,When I search for...,Then I...,see...,in the top ... results
0,a,should,https://www.gov.uk/a,1
"""
      expected = []
      assert_equal expected, checks(data)
    end

    should_eventually "allow non www.gov.uk URLS"
  end
end