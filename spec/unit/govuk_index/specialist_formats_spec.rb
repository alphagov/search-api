require "spec_helper"

RSpec.describe GovukIndex::ElasticsearchPresenter, "Specialist formats" do
  before do
    allow_any_instance_of(Indexer::PopularityLookup).to receive(:lookup_popularities).and_return({})
  end

  it "aaib report" do
    custom_metadata = {
      "date_of_occurrence" => "2015-10-10",
      "aircraft_category" => %w[commercial-fixed-wing],
      "report_type" => "annual-safety-report",
      "location" => "Near Popham Airfield, Hampshire",
      "aircraft_type" => "Alpi (Cavaciuti) Pioneer 400",
      "registration" => "G-CGVO",
    }
    special_formated_output = {
      "report_type" => %w[annual-safety-report],
      "location" => ["Near Popham Airfield, Hampshire"],
    }
    document = build_example_with_metadata(custom_metadata)
    expect_document_include_hash(document, custom_metadata.merge(special_formated_output))
  end

  it "asylum support decision" do
    custom_metadata = {
      "hidden_indexable_content" => "some hidden content",
      "tribunal_decision_categories" => %w[section-95-support-for-asylum-seekers],
      "tribunal_decision_decision_date" => "2015-10-10",
      "tribunal_decision_judges" => %w[bayati-c],
      "tribunal_decision_landmark" => "not-landmark",
      "tribunal_decision_reference_number" => "1234567890",
      "tribunal_decision_sub_categories" => %w[section-95-destitution],
    }
    # The following fields are valid for the object, however they can not be edited in the
    # front end.
    # * tribunal_decision_category
    # * tribunal_decision_sub_category

    document = build_example_with_metadata(custom_metadata)
    expect_document_include_hash(document, custom_metadata)
    expect(document[:indexable_content]).to eq("some hidden content")
  end

  it "business finance support scheme" do
    custom_metadata = {
      "business_sizes" => %w[under-10 between-10-and-249],
      "business_stages" => %w[start-up],
      "continuation_link" => "https://www.gov.uk",
      "industries" => %w[information-technology-digital-and-creative],
      "regions" => %w[northern-ireland],
      "types_of_support" => %w[finance],
      "will_continue_on" => "on GOV.UK",
    }
    document = build_example_with_metadata(custom_metadata)
    expect_document_include_hash(document, custom_metadata)
  end

  it "cma case" do
    custom_metadata = {
      "opened_date" => "2014-01-01",
      "closed_date" => "2015-01-01",
      "case_type" => "ca98-and-civil-cartels",
      "case_state" => "closed",
      "market_sector" => %w[energy],
      "outcome_type" => "ca98-no-grounds-for-action-non-infringement",
    }
    special_formated_output = {
      "case_type" => %w[ca98-and-civil-cartels],
      "case_state" => %w[closed],
    }
    document = build_example_with_metadata(custom_metadata)
    expect_document_include_hash(document, custom_metadata.merge(special_formated_output))
  end

  it "countryside stewardship grant" do
    custom_metadata = {
      "grant_type" => "option",
      "land_use" => %w[priority-habitats trees-non-woodland uplands],
      "tiers_or_standalone_items" => %w[higher-tier],
      "funding_amount" => %w[201-to-300],
    }
    special_formated_output = {
      "grant_type" => %w[option],
    }
    document = build_example_with_metadata(custom_metadata)
    expect_document_include_hash(document, custom_metadata.merge(special_formated_output))
  end

  it "dfid research output" do
    custom_metadata = {
      "dfid_document_type" => "book_chapter",
      "country" => %w[GB],
      "dfid_authors" => ["Mr. Potato Head", "Mrs. Potato Head"],
      "dfid_theme" => %w[infrastructure],
      "first_published_at" => "2016-04-28",
    }
    document = build_example_with_metadata(custom_metadata)
    expect_document_include_hash(document, custom_metadata)
  end

  it "drug safety update" do
    custom_metadata = {
      "therapeutic_area" => %w[cancer haematology immunosuppression-transplantation],
    }
    document = build_example_with_metadata(custom_metadata)
    expect_document_include_hash(document, custom_metadata)
  end

  it "employment appeal tribunal decision" do
    custom_metadata = {
      "hidden_indexable_content" => "hidden content",
      "tribunal_decision_categories" => %w[age-discrimination],
      "tribunal_decision_decision_date" => "2015-07-30",
      "tribunal_decision_landmark" => "landmark",
      "tribunal_decision_sub_categories" => %w[contract-of-employment-apprenticeship],
    }
    document = build_example_with_metadata(custom_metadata)
    expect_document_include_hash(document, custom_metadata)
    expect(document[:indexable_content]).to eq("hidden content")
  end

  it "employment tribunal decision" do
    custom_metadata = {
      "hidden_indexable_content" => "hidden etd content",
      "tribunal_decision_categories" => %w[age-discrimination],
      "tribunal_decision_country" => "england-and-wales",
      "tribunal_decision_decision_date" => "2015-07-30",
    }
    document = build_example_with_metadata(custom_metadata)
    expect_document_include_hash(document, custom_metadata)
    expect(document[:indexable_content]).to eq("hidden etd content")
  end

  it "european structural investment fund" do
    custom_metadata = {
      "closing_date" => "2016-01-01",
      "fund_state" => "open",
      "fund_type" => %w[business-support],
      "location" => %w[south-west],
      "funding_source" => %w[european-regional-development-fund],
    }
    special_formated_output = {
      "fund_state" => %w[open],
    }
    document = build_example_with_metadata(custom_metadata)
    expect_document_include_hash(document, custom_metadata.merge(special_formated_output))
  end

  it "international development fund" do
    custom_metadata = {
      "closing_date" => "2016-01-01",
      "fund_state" => "open",
      "fund_type" => %w[business-support],
      "location" => %w[south-west],
      "funding_source" => %w[european-regional-development-fund],
    }
    special_formated_output = {
      "fund_state" => %w[open],
    }
    document = build_example_with_metadata(custom_metadata)
    expect_document_include_hash(document, custom_metadata.merge(special_formated_output))
  end

  it "maib report" do
    custom_metadata = {
      "date_of_occurrence" => "2015-10-10",
      "report_type" => "investigation-report",
      "vessel_type" => %w[merchant-vessel-100-gross-tons-or-over],
    }
    special_formated_output = {
      "report_type" => %w[investigation-report],
    }
    document = build_example_with_metadata(custom_metadata)
    expect_document_include_hash(document, custom_metadata.merge(special_formated_output))
  end

  it "medical safety alert" do
    custom_metadata = {
      "alert_type" => "company-led-drugs",
      "issued_date" => "2016-02-01",
      "medical_specialism" => %w[anaesthetics cardiology],
    }
    special_formated_output = {
      "alert_type" => %w[company-led-drugs],
    }
    document = build_example_with_metadata(custom_metadata)
    expect_document_include_hash(document, custom_metadata.merge(special_formated_output))
  end

  it "raib report" do
    custom_metadata = {
      "date_of_occurrence" => "2015-10-10",
      "report_type" => "investigation-report",
      "railway_type" => %w[heavy-rail],
    }
    special_formated_output = {
      "report_type" => %w[investigation-report],
    }
    document = build_example_with_metadata(custom_metadata)
    expect_document_include_hash(document, custom_metadata.merge(special_formated_output))
  end

  it "research for development output" do
    custom_metadata = {
      "research_document_type" => "book_chapter",
      "country" => %w[GB],
      "authors" => ["Mr. Potato Head", "Mrs. Potato Head"],
      "theme" => %w[infrastructure],
      "first_published_at" => "2016-04-28",
    }
    document = build_example_with_metadata(custom_metadata)
    expect_document_include_hash(document, custom_metadata)
  end

  it "service standard report" do
    custom_metadata = {
      "assessment_date" => "2016-10-10",
    }
    document = build_example_with_metadata(custom_metadata)
    expect_document_include_hash(document, custom_metadata)
  end

  it "statutory instrument" do
    custom_metadata = {
      "laid_date" => "2018-06-01",
      "sift_end_date" => "2018-09-01",
      "sifting_status" => "closed",
      "withdrawn_date" => "2018-07-01",
    }
    special_formated_output = {
      "laid_date" => "2018-06-01",
      "sifting_status" => "closed",
    }
    document = build_example_with_metadata(custom_metadata)
    expect_document_include_hash(document, custom_metadata.merge(special_formated_output))
  end

  it "tax tribunal decision" do
    custom_metadata = {
      "hidden_indexable_content" => "hidden ttd content",
      "tribunal_decision_category" => "banking",
      "tribunal_decision_decision_date" => "2015-07-30",
    }
    document = build_example_with_metadata(custom_metadata)
    expect_document_include_hash(document, custom_metadata)
    expect(document[:indexable_content]).to eq("hidden ttd content")
  end

  it "utaac decision" do
    custom_metadata = {
      "hidden_indexable_content" => "hidden utaac content",
      "tribunal_decision_categories" => ["Benefits for children"],
      "tribunal_decision_decision_date" => "2016-01-01",
      "tribunal_decision_judges" => %w[angus-r],
      "tribunal_decision_sub_categories" => %w[benefits-for-children-benefit-increases-for-children],
    }
    document = build_example_with_metadata(custom_metadata)
    expect_document_include_hash(document, custom_metadata)
    expect(document[:indexable_content]).to eq("hidden utaac content")
  end

private

  def build_example_with_metadata(metadata)
    example = GovukSchemas::RandomExample.for_schema(notification_schema: "specialist_document") do |payload|
      payload["details"]["metadata"] = metadata
      payload
    end

    type_mapper = GovukIndex::DocumentTypeMapper.new(example)
    described_class.new(payload: example, type_mapper: type_mapper).document
  end

  def expect_document_include_hash(document, hash)
    hash.each do |key, value|
      expect(document[key.to_sym]).to eq(value),
                                      "Value for #{key}: `#{document[key.to_sym]}` did not match expected value `#{value}`"
    end
  end
end
