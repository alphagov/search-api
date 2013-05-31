class OrganisationSetPresenter

  def initialize(organisations)
    @organisations = organisations
  end

  def present_with_total
    MultiJson.encode({
      total: @organisations.size,
      results: @organisations.map { |organisation| build_result(organisation) }
    })
  end

private
  def build_result(organisation)
    slug = organisation.link.gsub(%r{^/government/organisations/}, "")
    organisation.to_hash.merge(slug: slug)
  end
end
