require "test_helper"
require "section"

class SectionTest < Test::Unit::TestCase

  def test_section_provides_path
    section = Section.new("bob")
    assert_equal "/browse/bob", section.path
  end

  def test_section_formats_name
    section = Section.new("this-and-that")
    assert_equal "This and that", section.name
  end

  def test_section_slug_accessible
    section = Section.new("bob")
    assert_equal "bob", section.slug
  end

end
