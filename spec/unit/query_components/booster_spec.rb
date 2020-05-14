require "spec_helper"

RSpec.describe QueryComponents::Booster do
  it "apply a multiplying factor" do
    builder = described_class.new(search_query_params)
    result = builder.wrap({ some: "query" })

    expect(:multiply).to eq(result[:function_score][:boost_mode])
    expect(:multiply).to eq(result[:function_score][:score_mode])
  end

  it "boost results by individual format weightings" do
    builder = described_class.new(search_query_params)
    result = builder.wrap({ some: "query" })

    expect_format_boost(result, "contact", 0.3)
    expect_format_boost(result, "service_manual_guide", 0.3)
    expect_format_boost(result, "transaction", 1.5)
  end

  it "not apply a boost to unspecified formats" do
    builder = described_class.new(search_query_params)
    result = builder.wrap({ some: "query" })

    expect_no_format_boost(result, "guide")
    expect_no_format_boost(result, "some_other_format")
  end

  it "downweight old organisations" do
    builder = described_class.new(search_query_params)
    result = builder.wrap({ some: "query" })

    expect_organisation_state_boost(result, "closed", 0.2)
    expect_organisation_state_boost(result, "devolved", 0.3)
  end

  it "downweight historic pages" do
    builder = described_class.new(search_query_params)
    result = builder.wrap({ some: "query" })

    expect_boost_for_field(result, :is_historic, true, 0.5)
  end

  it "boost announcements by date" do
    Timecop.freeze("2016-03-11 16:00".to_time) do
      builder = described_class.new(search_query_params)
      result = builder.wrap({ some: "query" })

      announcement_boost = result[:function_score][:functions].detect { |f| f[:filter][:term][:search_format_types] == "announcement" }
      expect(announcement_boost).not_to be_nil, "Could not find boost for announcements"

      script_score = announcement_boost[:script_score]

      expected_time_in_millis = 1_457_712_000_000
      expect(expected_time_in_millis).to eq(script_score[:script][:params][:now])
      expect(script_score[:script][:source]).to match(/doc\['public_timestamp'\]/)
    end
  end

  it "not boost government index results" do
    builder = described_class.new(search_query_params)
    result = builder.wrap({ some: "query" })

    expect_no_format_boost(result, "case_study")
    expect_no_format_boost(result, "take_part")
    expect_no_format_boost(result, "worldwide_organisation")
  end

  it "apply only individual format weightings for government formats" do
    builder = described_class.new(search_query_params)
    result = builder.wrap({ some: "query" })

    expect_format_boost(result, "minister", 1.7)
    expect_format_boost(result, "organisation", 2.5)
    expect_format_boost(result, "topic", 1.5)
  end

  it "boost guidance content" do
    builder = described_class.new(search_query_params)
    result = builder.wrap({ some: "query" })

    expect_boost_for_field(result, :navigation_document_supertype, "guidance", 2.5)
  end

  it "downweight service assessments by large amount" do
    builder = described_class.new(search_query_params)
    result = builder.wrap({ some: "query" })

    expect_format_boost(result, "service_standard_report", 0.05)
  end

  it "downweight FOI requests" do
    builder = described_class.new(search_query_params)
    result = builder.wrap({ some: "query" })

    expect_boost_for_field(result, :content_store_document_type, "foi_release", 0.2)
  end

  def expect_format_boost(result, content_format, expected_weight)
    expect_boost_for_field(result, :format, content_format, expected_weight)
  end

  def expect_no_format_boost(result, content_format)
    expect_no_boost_for_field(result, :format, content_format)
  end

  def expect_organisation_state_boost(result, state, expected_weight)
    expect_boost_for_field(result, :organisation_state, state, expected_weight)
  end

  def expect_boost_for_field(result, field, value, expected_weight)
    boost = result[:function_score][:functions].detect { |f| f[:filter][:term][field] == value }
    expect(boost).not_to be_nil, "Could not find boost for '#{field}': '#{value}'"
    expect(expected_weight).to be_within(0.001).of(boost[:weight])
  end

  def expect_no_boost_for_field(result, field, value)
    format_boost = result[:function_score][:functions].select { |f| f[:filter][:term][field] == value }
    expect(format_boost).to be_empty, "Found unexpected boost for '#{field}' #{value}"
  end
end
