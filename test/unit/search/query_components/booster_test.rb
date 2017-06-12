require "test_helper"
require "search/query_builder"

class BoosterTest < ShouldaUnitTestCase
  should "apply a multiplying factor" do
    builder = QueryComponents::Booster.new(search_query_params)
    result = builder.wrap({ some: 'query' })

    assert_equal :multiply, result[:function_score][:boost_mode]
    assert_equal "multiply", result[:function_score][:score_mode]
  end

  should "boost results by format" do
    builder = QueryComponents::Booster.new(search_query_params)
    result = builder.wrap({ some: 'query' })

    assert_format_boost(result, "organisation", 2.5)
    assert_format_boost(result, "service_manual_guide", 0.3)
    assert_format_boost(result, "mainstream_browse_page", 0)
  end

  should "downweight old organisations" do
    builder = QueryComponents::Booster.new(search_query_params)
    result = builder.wrap({ some: 'query' })

    assert_organisation_state_boost(result, "closed", 0.2)
    assert_organisation_state_boost(result, "devolved", 0.3)
  end

  should "downweight historic pages" do
    builder = QueryComponents::Booster.new(search_query_params)
    result = builder.wrap({ some: 'query' })

    historic_boost = result[:function_score][:functions].detect { |f| f[:filter][:term][:is_historic] }
    refute_nil historic_boost, "Could not find boost for 'is_historic'"
    assert_equal 0.5, historic_boost[:boost_factor]
  end

  should "boost announcements by date" do
    Timecop.freeze("2016-03-11 16:00".to_time) do
      builder = QueryComponents::Booster.new(search_query_params)
      result = builder.wrap({ some: 'query' })

      announcement_boost = result[:function_score][:functions].detect { |f| f[:filter][:term][:search_format_types] == "announcement" }
      refute_nil announcement_boost, "Could not find boost for announcements"

      script_score = announcement_boost[:script_score]

      expected_time_in_millis = 1457712000000
      assert_equal expected_time_in_millis, script_score[:params][:now]
      assert_match(/doc\['public_timestamp'\]/, script_score[:script])
    end
  end

  def assert_format_boost(result, content_format, expected_boost_factor)
    format_boost = result[:function_score][:functions].detect { |f| f[:filter][:term][:format] == content_format }
    refute_nil format_boost, "Could not find boost for format '#{content_format}'"
    assert_equal expected_boost_factor, format_boost[:boost_factor]
  end

  def assert_organisation_state_boost(result, state, expected_boost_factor)
    state_boost = result[:function_score][:functions].detect { |f| f[:filter][:term][:organisation_state] == state }
    refute_nil state_boost, "Could not find boost for organisation state '#{state}'"
    assert_equal expected_boost_factor, state_boost[:boost_factor]
  end
end
