require 'spec_helper'

RSpec.describe Search::QueryParameters, tags: ['shoulda'] do
  context "quoted_search_phrase?" do
    it "return false if query isn't quote enclosed" do
      params = described_class.new(query: "my query")
      assert_equal false, params.quoted_search_phrase?
    end

    it "return false if entire query isn't quote enclosed" do
      params = described_class.new(query: %{This is "part of my" query})
      assert_equal false, params.quoted_search_phrase?
    end

    it "return false if query doesn't have ending quotes" do
      params = described_class.new(query: %{"unclosed quotes})
      assert_equal false, params.quoted_search_phrase?
    end

    it "return false if query doesn't have starting quotes" do
      params = described_class.new(query: %{unclosed quotes"})
      assert_equal false, params.quoted_search_phrase?
    end

    it "return true if query enclosed with quotes" do
      params = described_class.new(query: %{"phrase enclosed with quotes"})
      assert_equal true, params.quoted_search_phrase?
    end

    it "return false if enclosed with quotes but has intervening quotes" do
      params = described_class.new(query: %{"phrase enclosed with quotes and "quotes" in the middle})
      assert_equal false, params.quoted_search_phrase?
    end

    it "return true if query enclosed with quotes but with leading whitespace" do
      params = described_class.new(query: %{  \t  "phrase enclosed with quotes"})
      assert_equal true, params.quoted_search_phrase?
    end

    it "return true if query enclosed with quotes but with trailing whitespace" do
      params = described_class.new(query: %{"phrase enclosed with quotes"  \t  })
      assert_equal true, params.quoted_search_phrase?
    end

    it "return false if the query is nil" do
      params = described_class.new
      assert_equal false, params.quoted_search_phrase?
    end
  end

  context "query" do
    it "return the query if there are no enclosing quotes" do
      params = described_class.new(query: %{my query})
      assert_equal %{my query}, params.query
    end

    it "return the query with enclosing quotes if there are embedded quotes" do
      params = described_class.new(query: %{"Enclosing quotes but with "embedded" quotes"})
      assert_equal %{"Enclosing quotes but with "embedded" quotes"}, params.query
    end

    it "not strip leading and trailing whitespace if phrase is enclosed in quotes" do
      params = described_class.new(query: %{  \t "Enclosing quotes"\t  })
      assert_equal %{  \t "Enclosing quotes"\t  }, params.query
    end

    it "not strip leading and trailing whitespace if not enclosed in quotes" do
      params = described_class.new(query: %{  my query  })
      assert_equal %{  my query  }, params.query
    end

    it "not strip leading and trailing whitespace if phrase contains embedded quotes" do
      params = described_class.new(query: %{  \t"Enclosing quotes but with "embedded" quotes"  })
      assert_equal %{  \t"Enclosing quotes but with "embedded" quotes"  }, params.query
    end
  end
end
