require "spec_helper"
require_relative "../../support/best_bet_test_helpers"

RSpec.describe "best/worst bet functionality" do
  include BestBetTestHelpers

  it "boosts exact best bets" do
    commit_document(
      "govuk_test",
      {
        "link" => "/an-organic-result",
        "indexable_content" => 'I will turn up in searches for "a forced best bet"',
        "format" => "answer",
      },
    )

    commit_document(
      "govuk_test",
      {
        "link" => "/the-link-that-should-surface",
        "indexable_content" => "Empty.",
        "format" => "answer",
      },
    )

    add_best_bet(
      query: "a forced best bet",
      type: "exact",
      link: "/the-link-that-should-surface",
      position: 1,
    )

    links = get_links "/search?q=a+forced+best+bet"

    expect(links).to eq(["/the-link-that-should-surface", "/an-organic-result"])
  end

  it "works when links do not match IDs" do
    commit_document(
      "govuk_test",
      {
        "link" => "/an-organic-result",
        "indexable_content" => 'I will turn up in searches for "a forced best bet"',
        "format" => "answer",
      },
    )

    commit_document(
      "govuk_test",
      {
        "link" => "https://www.nhs.uk",
        "indexable_content" => 'I will turn up in searches for "a forced best bet"',
        "format" => "answer",
      },
      id: "31e59fa7-ce2f-48b7-ba85-2f5535220cd0",
    )

    add_best_bet(
      query: "a forced best bet",
      type: "exact",
      link: "https://www.nhs.uk",
      position: 1,
    )

    links = get_links "/search?q=a+forced+best+bet"

    expect(links).to eq(["https://www.nhs.uk", "/an-organic-result"])
  end

  it "hides worst bets" do
    commit_document(
      "govuk_test",
      {
        "indexable_content" => "I should not be shown.",
        "link" => "/we-never-show-this",
        "format" => "answer",
      },
    )

    add_worst_bet(
      query: "shown",
      type: "exact",
      link: "/we-never-show-this",
      position: 1,
    )

    links = get_links "/search?q=shown"

    expect(links).not_to include("/we-never-show-this")
  end

  it "boosts stemmed best bets when the terms match exactly" do
    commit_document(
      "govuk_test",
      {
        "link" => "/the-link-that-should-surface",
        "format" => "answer",
      },
    )

    add_best_bet(
      query: "best bet",
      type: "stemmed",
      link: "/the-link-that-should-surface",
      position: 1,
    )

    links = get_links "/search?q=best+bet+and+such"

    expect(links).to eq(["/the-link-that-should-surface"])
  end

  it "boosts stemmed best bets when only the stems of the terms match" do
    commit_document(
      "govuk_test",
      {
        "link" => "/the-link-that-should-surface",
        "format" => "answer",
      },
    )

    add_best_bet(
      query: "best bet",
      type: "stemmed",
      link: "/the-link-that-should-surface",
      position: 1,
    )

    # NOTE: We're searching for "bests bet", not "best bet" here.
    links = get_links "/search?q=bests+bet"

    expect(links).to eq(["/the-link-that-should-surface"])
  end

  it "boosts stemmed best bets when the terms appear out of order" do
    commit_document(
      "govuk_test",
      {
        "link" => "/only-shown-for-exact-matches",
        "format" => "answer",
      },
    )

    add_best_bet(
      query: "best bet",
      type: "stemmed",
      link: "/only-shown-for-exact-matches",
      position: 1,
    )

    # NOTE: We're searching for "bet best", not "best bet" here.
    links = get_links "/search?q=bet+best"

    expect(links).not_to include("/only-shown-for-exact-matches")
  end
end
