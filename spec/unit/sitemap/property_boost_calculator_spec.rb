require "spec_helper"

RSpec.describe PropertyBoostCalculator do
  it "boosts are between 0 and 1" do
    stub_boost_config({
      "format" => {
        "format1" => 0,
        "format2" => 1,
        "format3" => 2,
        "format4" => 3,
        "format5" => 10,
      },
    })

    calculator = subject

    expect(calculator.boost(build_document(format: "format1"))).to eq(0)
    expect(calculator.boost(build_document(format: "format2"))).to eq(0.5)
    expect(calculator.boost(build_document(format: "format3"))).to eq(0.75)
    expect(calculator.boost(build_document(format: "format4"))).to eq(0.88)
    expect(calculator.boost(build_document(format: "format5"))).to eq(1)
  end

  it "unboosted format has default boost" do
    stub_boost_config({
      "format" => {
        "some_format" => 1,
      },
    })

    calculator = subject

    expect(calculator.boost(build_document(format: "some_format"))).to eq(0.5)
  end

  it "boosts limit is 1" do
    stub_boost_config({
      "format" => {
        "format1" => 10,
        "format2" => 100,
        "format3" => 1000,
      },
    })

    calculator = subject

    expect(calculator.boost(build_document(format: "format1"))).to eq(1)
    expect(calculator.boost(build_document(format: "format2"))).to eq(1)
    expect(calculator.boost(build_document(format: "format3"))).to eq(1)
  end

  it "unconfigured format has default boost" do
    stub_boost_config({
      "format" => {
        "some_format" => 0.3,
      },
    })

    calculator = subject

    expect(calculator.boost(build_document(format: "other_format"))).to eq(0.5)
  end

  it "unconfigured property has default boost" do
    stub_boost_config({
      "some_other_property" => {
        "some_value" => 0.3,
      },
    })

    calculator = subject

    expect(calculator.boost(build_document(document_type: "some_doc_type"))).to eq(0.5)
  end

  it "withdrawn status divides the calculated priority by four" do
    document = build_document(
      is_withdrawn: true,
    )

    # default boost is 0.5 as above
    expect(subject.boost(document)).to eq(0.125)
  end

  it "boosts are rounded" do
    stub_boost_config({
      "format" => {
        "format1" => 0.123,
        "format2" => 0.456,
      },
    })

    calculator = subject

    expect(calculator.boost(build_document(format: "format1"))).to eq(0.08)
    expect(calculator.boost(build_document(format: "format2"))).to eq(0.27)
  end

  it "boosts for different fields are combined" do
    stub_boost_config({
      "format" => {
        "publication" => 0.5,
      },
      "content_store_document_type" => {
        "foi_release" => 0.2,
      },
      "navigation_document_supertype" => {
        "guidance" => 0.8,
      },
    })

    calculator = subject

    document = {
      "format" => "publication",
      "content_store_document_type" => "foi_release",
      "navigation_document_supertype" => "some_other_value",
    }

    #   1 - 2^(-format boost * document type boost * navigation supertype boost)
    # = 1 - 2^(-0.5 * 0.2 * 1)
    # = 0.07
    expect(calculator.boost(document)).to eq(0.07)
  end

  it "external search overrides are applied" do
    config = {
      "base" => {
        "format" => {
          "service_manual_guide" => 1,
        },
      },
      "external_search" => {
        "format" => {
          "service_manual_guide" => 2,
        },
      },
    }
    stub_full_config(config)

    calculator = subject

    # 1 - 2^(-boost_override) = 1 - 2^(-2) = 0.75
    expected_boost_override = 0.75
    actual_boost = calculator.boost(build_document(format: "service_manual_guide"))
    expect(expected_boost_override).to eq(actual_boost)
  end

  def stub_boost_config(boosts)
    stub_full_config({
      "base" => boosts,
    })
  end

  def stub_full_config(config)
    allow(YAML).to receive(:load_file).and_return(config)
  end

  def build_document(format: nil, document_type: nil, is_withdrawn: nil)
    attributes = {}
    attributes["format"] = format if format
    attributes["content_store_document_type"] = document_type if document_type
    attributes["is_withdrawn"] = is_withdrawn unless is_withdrawn.nil?

    attributes
  end
end
