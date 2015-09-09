module HealthCheck
  Result = Struct.new(
    :success, :score, :possible_score,
    :success_label, :found_label, :path,
    :search_term, :position_found, :expectation
  )
end
