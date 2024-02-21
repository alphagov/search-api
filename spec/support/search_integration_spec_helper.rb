module SearchIntegrationSpecHelper
  def commit_ministry_of_magic_document(params = {})
    document_params = {
      "slug" => "/ministry-of-magic",
      "link" => "/ministry-of-magic-site",
      "title" => "Ministry of Magic",
    }
    document_params.merge!(params)
    index = params["index"] || "government_test"
    commit_document(index, document_params)
  end

  def commit_treatment_of_dragons_document(params = {})
    document_params = {
      "title" => "Advice on Treatment of Dragons",
      "link" => "/dragon-guide",
    }
    document_params.merge!(params)
    index = params["index"] || "government_test"
    commit_document(index, document_params)
  end

  def cma_case_attributes(attributes = {})
    {
      "title" => "Somewhat Unique CMA Case",
      "link" => "/cma-cases/somewhat-unique-cma-case",
      "indexable_content" => "Mergers of cheeses and faces",
      "opened_date" => "2014-04-01",
      "format" => "cma_case",
      "document_type" => "cma_case",
    }.merge(attributes)
  end

  def commit_filter_from_date_documents
    commit_document(
      "govuk_test",
      cma_case_attributes("opened_date" => "2014-03-30", "link" => "/old-cma-with-date"),
      type: "cma_case",
    )
    commit_document(
      "govuk_test",
      cma_case_attributes("opened_date" => "2014-03-30T23:00:00.000+00:00", "link" => "/old-cma-with-datetime"),
      type: "cma_case",
    )
    commit_document(
      "govuk_test",
      cma_case_attributes("opened_date" => "2014-03-31", "link" => "/matching-cma-with-date"),
      type: "cma_case",
    )
    commit_document(
      "govuk_test",
      cma_case_attributes("opened_date" => "2014-03-31T00:00:00.000+00:00", "link" => "/matching-cma-with-datetime"),
      type: "cma_case",
    )
  end

  def commit_filter_from_time_documents
    commit_document(
      "govuk_test",
      cma_case_attributes("opened_date" => "2014-03-31", "link" => "/old-cma-with-date"),
      type: "cma_case",
    )
    commit_document(
      "govuk_test",
      cma_case_attributes("opened_date" => "2014-03-31T13:59:59.000+00:00", "link" => "/old-cma-with-datetime"),
      type: "cma_case",
    )
    commit_document(
      "govuk_test",
      cma_case_attributes("opened_date" => "2014-04-01", "link" => "/matching-cma-with-date"),
      type: "cma_case",
    )
    commit_document(
      "govuk_test",
      cma_case_attributes("opened_date" => "2014-03-31T14:00:00.000+00:00", "link" => "/matching-cma-with-datetime"),
      type: "cma_case",
    )
  end

  def commit_filter_to_date_documents
    commit_document(
      "govuk_test",
      cma_case_attributes("opened_date" => "2014-04-02", "link" => "/matching-cma-with-date"),
      type: "cma_case",
    )
    commit_document(
      "govuk_test",
      cma_case_attributes("opened_date" => "2014-04-02T05:00:00.000+00:00", "link" => "/matching-cma-with-datetime"),
      type: "cma_case",
    )
    commit_document(
      "govuk_test",
      cma_case_attributes("opened_date" => "2014-04-03", "link" => "/future-cma-with-date"),
      type: "cma_case",
    )
    commit_document(
      "govuk_test",
      cma_case_attributes("opened_date" => "2014-04-03T00:00:00.000+00:00", "link" => "/future-cma-with-datetime"),
      type: "cma_case",
    )
  end

  def commit_filter_to_time_documents
    commit_document(
      "govuk_test",
      cma_case_attributes("opened_date" => "2014-04-02", "link" => "/matching-cma-with-date"),
      type: "cma_case",
    )
    commit_document(
      "govuk_test",
      cma_case_attributes("opened_date" => "2014-04-02T11:00:00.000+00:00", "link" => "/matching-cma-with-datetime"),
      type: "cma_case",
    )
    commit_document(
      "govuk_test",
      cma_case_attributes("opened_date" => "2014-04-03", "link" => "/future-cma-with-date"),
      type: "cma_case",
    )
    commit_document(
      "govuk_test",
      cma_case_attributes("opened_date" => "2014-04-02T11:00:01.000+00:00", "link" => "/future-cma-with-datetime"),
      type: "cma_case",
    )
  end

  def expect_response_includes_matching_date_and_datetime_results(results)
    expect(results).to contain_exactly(
      hash_including("link" => "/matching-cma-with-date"),
      hash_including("link" => "/matching-cma-with-datetime"),
    )
  end

  def expect_result_includes_ministry_of_magic_for_key(result, key, additional_ministry_data = {})
    ministry_of_magic = {
      "slug" => "/ministry-of-magic",
      "link" => "/ministry-of-magic-site",
      "title" => "Ministry of Magic",
    }
    ministry_of_magic.merge!(additional_ministry_data)
    expect(result[key]).to eq(
      [
        ministry_of_magic,
      ],
    )
  end
end
