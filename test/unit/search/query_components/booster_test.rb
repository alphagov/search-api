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

    assert_boost_for_field(result, :is_historic, true, 0.5)
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

  context "when A/B testing format boosting" do
    context "when no variant is specified" do
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

      should "not boost guidance content" do
        builder = QueryComponents::Booster.new(search_query_params)
        result = builder.wrap({ some: 'query' })

        assert_no_boost_for_field(result, :navigation_document_supertype, "guidance")
      end
    end

    context "in the A variant" do
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

      should "not boost guidance content" do
        params = search_query_params(ab_tests: { format_boosting: "A" })
        builder = QueryComponents::Booster.new(params)
        result = builder.wrap({ some: 'query' })

        assert_no_boost_for_field(result, :navigation_document_supertype, "guidance")
      end
    end

    context "in the B variant" do
      should "not boost government index results" do
        params = search_query_params(ab_tests: { format_boosting: "B" })
        builder = QueryComponents::Booster.new(params)
        result = builder.wrap({ some: 'query' })

        assert_no_format_boost(result, "case_study")
        assert_no_format_boost(result, "take_part")
        assert_no_format_boost(result, "worldwide_organisation")
      end

      should "apply only individual format weightings for government formats" do
        params = search_query_params(ab_tests: { format_boosting: "B" })
        builder = QueryComponents::Booster.new(params)
        result = builder.wrap({ some: 'query' })

        assert_format_boost(result, "minister", 1.7)
        assert_format_boost(result, "organisation", 2.5)
        assert_format_boost(result, "topic", 1.5)
      end

      should "boost guidance content" do
        params = search_query_params(ab_tests: { format_boosting: "B" })
        builder = QueryComponents::Booster.new(params)
        result = builder.wrap({ some: 'query' })

        assert_boost_for_field(result, :navigation_document_supertype, "guidance", 2.5)
      end
    end
  end

  def assert_format_boost(result, content_format, expected_boost_factor)
    assert_boost_for_field(result, :format, content_format, expected_boost_factor)
  end

  def assert_no_format_boost(result, content_format)
    assert_no_boost_for_field(result, :format, content_format)
  end

  def assert_organisation_state_boost(result, state, expected_boost_factor)
    assert_boost_for_field(result, :organisation_state, state, expected_boost_factor)
  end

  def assert_boost_for_field(result, field, value, expected_boost_factor)
    boost = result[:function_score][:functions].detect { |f| f[:filter][:term][field] == value }
    refute_nil boost, "Could not find boost for '#{field}': '#{value}'"
    assert_in_delta expected_boost_factor, boost[:boost_factor], 0.001
  end

  def assert_no_boost_for_field(result, field, value)
    format_boost = result[:function_score][:functions].select { |f| f[:filter][:term][field] == value }
    assert_empty format_boost, "Found unexpected boost for '#{field}' #{value}"
  end
end
