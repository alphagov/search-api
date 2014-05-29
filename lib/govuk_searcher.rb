# Combines search results across indices for the GOV.UK site search
class GovukSearcher
  def initialize(mainstream_index, detailed_index, government_index)
    @mainstream_index = mainstream_index
    @detailed_index = detailed_index
    @government_index = government_index
  end

  # Search and combine the indices and return a hash of ResultSet objects
  def search(query, organisation = nil, sort = nil)
    mainstream_results = @mainstream_index.search(query)
    detailed_results = @detailed_index.search(query)
    government_results = @government_index.search(query,
      organisation: organisation, sort: sort)

    if organisation || sort
      unfiltered_government_results = @government_index.search(query)
    else
      unfiltered_government_results = government_results
    end

    # si == services and information
    si_results = mainstream_results.merge(detailed_results.weighted(0.8))

    top_results = si_results.merge(unfiltered_government_results.weighted(0.6)).take(3)

    remaining_si = si_results - top_results
    remaining_government = government_results - top_results

    {
      "top-results" => top_results,
      "services-information" => remaining_si,
      "departments-policy" => remaining_government
    }
  end
end
