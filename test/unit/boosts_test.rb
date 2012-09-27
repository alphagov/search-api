require "test_helper"
require "app"

CSV_BOOSTS = <<eos
"/joker","clown prince of crime"
"/batman","dark knight, caped crusader"
eos

class BoostTest < Test::Unit::TestCase

  def test_should_parse_boosts_from_csv
    CSV.stubs(:read).returns(CSV.parse(CSV_BOOSTS))
    expected_boosts = {
      "/joker" => "clown prince of crime",
      "/batman" => "dark knight, caped crusader"
    }
    assert_equal expected_boosts, boosts
  end
end
