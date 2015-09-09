class SearchCheckReport
  def initialize(output_file: CSV.open('search_check_results.csv', 'wb'))
    @report = output_file
    @report << [
      "Pass or Fail",
      "Found or not",
      "Page",
      "Search Term",
      "Position found",
      "Position wanted"
    ]
  end

  def <<(result)
    @report << [
      result.success_label,
      result.found_label,
      result.path,
      result.search_term,
      result.position_found,
      result.expectation
    ]
  end
end
