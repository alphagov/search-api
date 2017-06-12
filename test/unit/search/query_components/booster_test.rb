require "test_helper"
require "search/query_builder"

class BoosterTest < ShouldaUnitTestCase
  should "apply a multiplying factor" do
    builder = QueryComponents::Booster.new(search_query_params)
    result = builder.wrap({ some: 'query' })

    assert_equal :multiply, result[:function_score][:boost_mode]
    assert_equal :multiply, result[:function_score][:score_mode]
  end

  should "boost results by individual format weightings" do
    builder = QueryComponents::Booster.new(search_query_params)
    result = builder.wrap({ some: 'query' })

    assert_format_boost(result, "contact", 0.3)
    assert_format_boost(result, "service_manual_guide", 0.3)
    assert_format_boost(result, "smart-answer", 1.5)
  end

  should "boost government index results" do
    builder = QueryComponents::Booster.new(search_query_params)
    result = builder.wrap({ some: 'query' })

    assert_format_boost(result, "case_study", 0.4)
    assert_format_boost(result, "take_part", 0.4)
    assert_format_boost(result, "worldwide_organisation", 0.4)
  end

  should "combine government index and individual format weightings" do
    builder = QueryComponents::Booster.new(search_query_params)
    result = builder.wrap({ some: 'query' })

    assert_format_boost(result, "minister", 0.68)
    assert_format_boost(result, "organisation", 1.0)
    assert_format_boost(result, "topic", 0.6)
  end

  should "not apply a boost to unspecified formats" do
    builder = QueryComponents::Booster.new(search_query_params)
    result = builder.wrap({ some: 'query' })

    assert_no_format_boost(result, "guide")
    assert_no_format_boost(result, "some_other_format")
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
    assert_in_delta expected_boost_factor, format_boost[:boost_factor], 0.001
  end

  def assert_no_format_boost(result, content_format)
    format_boosts = result[:function_score][:functions].select { |f| f[:filter][:term][:format] == content_format }
    assert_empty format_boosts, "Found unexpected boost for format #{content_format}"
  end

  def assert_organisation_state_boost(result, state, expected_boost_factor)
    state_boost = result[:function_score][:functions].detect { |f| f[:filter][:term][:organisation_state] == state }
    refute_nil state_boost, "Could not find boost for organisation state '#{state}'"
    assert_equal expected_boost_factor, state_boost[:boost_factor]
  end
end
