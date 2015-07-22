require "active_support/core_ext/string"

# Calculates the snippet for a search result. This will be the place to add
# highlighting and fragments.
class Snippet
  attr_reader :document

  def initialize(document)
    @document = document
  end

  def text
    if document['format'] == "organisation" && document["organisation_state"] != "closed"
      description_with_organisation_prefix
    elsif original_description.blank? && document["format"] == "specialist_sector"
      "List of information about #{document["title"]}."
    else
      truncated_description
    end
  end

private

  def description_with_organisation_prefix
    "The home of #{document["title"]} on GOV.UK. #{truncated_description}"
  end

  def truncated_description
    original_description.truncate(215, separator: " ", omission: '…')
  end

  def original_description
    document['description'] || ""
  end
end
