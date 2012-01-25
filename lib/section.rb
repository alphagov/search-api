class Section

  attr_reader :slug

  def initialize(slug)
    @slug = slug
  end

  def path
    "/browse/#{@slug}"
  end

  def name
    @slug
  end

end
