require "test_helper"
require "search_parameters"


class SearchParameterTest < ShouldaUnitTestCase
  context "quoted_search_phrase?" do
    should "return false if query isn't quote enclosed" do
      params = SearchParameters.new(query: "my query")
      assert_equal false, params.quoted_search_phrase?
    end

    should "return false if entire query isn't quote enclosed" do
      params = SearchParameters.new(query: %Q{This is "part of my" query} )
      assert_equal false, params.quoted_search_phrase?
    end

    should "return false if query doesn't have ending quotes" do
      params = SearchParameters.new(query: %Q{"unclosed quotes} )
      assert_equal false, params.quoted_search_phrase?
    end

    should "return false if query doesn't have starting quotes" do
      params = SearchParameters.new(query: %Q{unclosed quotes"} )
      assert_equal false, params.quoted_search_phrase?
    end

    should "return true if query enclosed with quotes" do
      params = SearchParameters.new(query: %Q{"phrase enclosed with quotes"} )
      assert_equal true, params.quoted_search_phrase?
    end

    should "return false if enclosed with quotes but has intervening quotes" do
      params = SearchParameters.new(query: %Q{"phrase enclosed with quotes and "quotes" in the middle} )
      assert_equal false, params.quoted_search_phrase?
    end

    should "return true if query enclosed with quotes but with leading whitespace" do
      params = SearchParameters.new(query: %Q{  \t  "phrase enclosed with quotes"} )
      assert_equal true, params.quoted_search_phrase?
    end

    should "return true if query enclosed with quotes but with trailing whitespace" do
      params = SearchParameters.new(query: %Q{"phrase enclosed with quotes"  \t  } )
      assert_equal true, params.quoted_search_phrase?
    end

    should "return false if the query is nil" do
      params = SearchParameters.new
      assert_equal false, params.quoted_search_phrase?
    end
  end

  context "query" do
    should "return the query if there are no enclosing quotes" do
      params = SearchParameters.new(query: %Q{my query})
      assert_equal %Q{my query}, params.query
    end

    should "return the query with enclosing quotes if there are embedded quotes" do
      params = SearchParameters.new(query: %Q{"Enclosing quotes but with "embedded" quotes"})
      assert_equal %Q{"Enclosing quotes but with "embedded" quotes"}, params.query
    end

    should "not strip leading and trailing whitespace if phrase is enclosed in quotes" do
      params = SearchParameters.new(query: %Q{  \t "Enclosing quotes"\t  })
      assert_equal %Q{  \t "Enclosing quotes"\t  }, params.query
    end

    should "not strip leading and trailing whitespace if not enclosed in quotes" do
      params = SearchParameters.new(query: %Q{  my query  })
      assert_equal %Q{  my query  }, params.query
    end

    should "not strip leading and trailing whitespace if phrase contains embedded quotes" do
      params = SearchParameters.new(query: %Q{  \t"Enclosing quotes but with "embedded" quotes"  })
      assert_equal %Q{  \t"Enclosing quotes but with "embedded" quotes"  }, params.query
    end
  end
end
