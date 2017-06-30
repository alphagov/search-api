require_relative "../../test_helper"
require "health_check/check_file_parser"

module HealthCheck
  class CheckFileParserTest < ShouldaUnitTestCase
    def checks(data)
      CheckFileParser.new(StringIO.new(data)).checks
    end

    should "read the supplied file and return a list of checks" do
      data = <<~END
        Tags,When I search for...,Then I...,see...,in the top ... results,Current position,Link,Last reviewed (Ctrl ;),Word count,Source,Duplicates?
        test,a,should,https://www.gov.uk/a,1
        test,b,should,https://www.gov.uk/b,1
      END

      expected = [SearchCheck.new("a", "should", "/a", 1, 1, %w(test)), SearchCheck.new("b", "should", "/b", 1, 1, %w(test))]
      assert_equal expected, checks(data)
    end

    should "skip rows that don't have an integer for the top N number" do
      data = <<~END
        Tags,When I search for...,Then I...,see...,in the top ... results,Current position,Link,Last reviewed (Ctrl ;),Word count,Source,Duplicates?
        test,b,should,https://www.gov.uk/b,mistake
      END

      expected = []
      assert_equal expected, checks(data)
    end

    should "skip rows that don't have a URL" do
      data = <<~END
        Tags,When I search for...,Then I...,see...,in the top ... results,Current position,Link,Last reviewed (Ctrl ;),Word count,Source,Duplicates?
        test,a,should,mistake,1
      END

      expected = []
      assert_equal expected, checks(data)
    end

    should "skip rows that don't have a imperative" do
      data = <<~END
        Tags,When I search for...,Then I...,see...,in the top ... results,Current position,Link,Last reviewed (Ctrl ;),Word count,Source,Duplicates?
        test,a,,https://www.gov.uk/a,1
      END

      expected = []
      assert_equal expected, checks(data)
    end

    should "skip rows that don't have a search term" do
      data = <<~END
        Tags,When I search for...,Then I...,see...,in the top ... results,Current position,Link,Last reviewed (Ctrl ;),Word count,Source,Duplicates?
        test,,should,https://www.gov.uk/a,1
      END

      expected = []
      assert_equal expected, checks(data)
    end
  end
end
