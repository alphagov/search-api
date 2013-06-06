require "test_helper"
require "result_promoter"

class ResultPromoterTest < MiniTest::Unit::TestCase
  def test_can_identify_whether_a_query_contains_a_promoted_term
    result_promoter = ResultPromoter.new
    result_promoter.add("/jobsearch", ["job", "jobs"])
    assert_equal ["jobs"], result_promoter.promoted_terms_in("jobs in birmingham")
    assert_equal [], result_promoter.promoted_terms_in("plumbing in birmingham")
    assert_equal ["job"], result_promoter.promoted_terms_in("job search")
    assert_equal ["job"], result_promoter.promoted_terms_in("job job")
    assert_equal [], result_promoter.promoted_terms_in("jobbing")
  end
end