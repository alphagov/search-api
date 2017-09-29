require 'spec_helper'


RSpec.describe HealthCheck::CheckFileParser do
  def checks(data)
    described_class.new(StringIO.new(data)).checks
  end

  it "read the supplied file and return a list of checks" do
    data = <<~END
      Tags,When I search for...,Then I...,see...,in the top ... results,Current position,Link,Last reviewed (Ctrl ;),Word count,Source,Duplicates?
      test,a,should,https://www.gov.uk/a,1
      test,b,should,https://www.gov.uk/b,1
    END

    expected = [
      HealthCheck::SearchCheck.new("a", "should", "/a", 1, 1, %w(test)),
      HealthCheck::SearchCheck.new("b", "should", "/b", 1, 1, %w(test))
    ]
    expect(expected).to eq(checks(data))
  end

  it "skip rows that don't have an integer for the top N number" do
    data = <<~END
      Tags,When I search for...,Then I...,see...,in the top ... results,Current position,Link,Last reviewed (Ctrl ;),Word count,Source,Duplicates?
      test,b,should,https://www.gov.uk/b,mistake
    END

    expected = []
    expect(expected).to eq(checks(data))
  end

  it "skip rows that don't have a URL" do
    data = <<~END
      Tags,When I search for...,Then I...,see...,in the top ... results,Current position,Link,Last reviewed (Ctrl ;),Word count,Source,Duplicates?
      test,a,should,mistake,1
    END

    expected = []
    expect(expected).to eq(checks(data))
  end

  it "skip rows that don't have a imperative" do
    data = <<~END
      Tags,When I search for...,Then I...,see...,in the top ... results,Current position,Link,Last reviewed (Ctrl ;),Word count,Source,Duplicates?
      test,a,,https://www.gov.uk/a,1
    END

    expected = []
    expect(expected).to eq(checks(data))
  end

  it "skip rows that don't have a search term" do
    data = <<~END
      Tags,When I search for...,Then I...,see...,in the top ... results,Current position,Link,Last reviewed (Ctrl ;),Word count,Source,Duplicates?
      test,,should,https://www.gov.uk/a,1
    END

    expected = []
    expect(expected).to eq(checks(data))
  end
end
