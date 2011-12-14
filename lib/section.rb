class Section

  def initialize(slug)
    @slug = slug
  end

  def path
    "/browse/#{@slug}"
  end

  def name
    @slug.gsub('-', ' ').capitalize
  end

end
