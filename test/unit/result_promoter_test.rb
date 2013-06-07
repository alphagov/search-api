require "test_helper"
require "result_promoter"

class ResultPromoterTest < MiniTest::Unit::TestCase
  def test_can_identify_whether_a_query_contains_a_promoted_term
    result_promoter = ResultPromoter.new([
      PromotedResult.new("/jobsearch", ["job", "jobs"])
    ])

    assert_equal ["jobs"], result_promoter.promoted_terms_in("jobs in birmingham")
    assert_equal [], result_promoter.promoted_terms_in("plumbing in birmingham")
    assert_equal ["job"], result_promoter.promoted_terms_in("job search")
    assert_equal ["job"], result_promoter.promoted_terms_in("job job")
    assert_equal [], result_promoter.promoted_terms_in("jobbing")
  end

  def test_with_promotion_sets_promoted_for_for_promoted_documents
    result_promoter = ResultPromoter.new([
      PromotedResult.new("/jobsearch", ["job", "jobs"])
    ])

    promoted = result_promoter.with_promotion({"link" => "/jobsearch"})
    assert_equal "job jobs", promoted["promoted_for"]
  end

  def test_with_promotion_does_not_set_promoted_for_for_other_documents
    result_promoter = ResultPromoter.new([
      PromotedResult.new("/jobsearch", ["job", "jobs"])
    ])

    promoted = result_promoter.with_promotion({"link" => "/tax-disc"})
    refute_includes promoted, "promoted_for"
  end

  def test_with_promotion_clears_promoted_for_if_a_document_has_it_set_already
    result_promoter = ResultPromoter.new([
      PromotedResult.new("/jobsearch", ["job", "jobs"])
    ])

    promoted = result_promoter.with_promotion({"link" => "/tax-disc", "promoted_for" => "jobs"})
    refute_includes promoted, "promoted_for"
  end

end