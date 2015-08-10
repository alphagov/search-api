require "active_support/core_ext/string"

# Calculates the snippet for a search result. This will be the place to add
# highlighting and fragments.
class Snippet
  attr_reader :document

  def initialize(document)
    @document = document
  end

  def text
    if needs_organsation_prefix?
      description_with_organisation_prefix
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

  def needs_organsation_prefix?
    document['format'] == "organisation" &&
      document["organisation_state"] != "closed" &&
      !document['description'].starts_with?("The home of")
  end
end
