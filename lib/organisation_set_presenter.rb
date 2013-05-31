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
    match_data = organisation.link.match(%r{^/government/organisations/(?<slug>[^/]+)$})
    if match_data
      slug = match_data[:slug]
      organisation.to_hash.merge(slug: slug)
    else
      organisation.to_hash
    end
  end
end
