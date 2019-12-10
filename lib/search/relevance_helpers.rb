module Search::RelevanceHelpers
  def self.ltr_enabled?
    ENV["ENABLE_LTR"].present? && ENV["ENABLE_LTR"] == "true"
  end
end
