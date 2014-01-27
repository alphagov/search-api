require "test_helper"
require "organisation_set_presenter"

class OrganisationSetPresenterTest < ShouldaUnitTestCase

  context "presenting organisations" do
    setup do
      @organisations = [
        stub("Org 1",
             link: "/government/organisations/foo",
             to_hash: {"title" => "Foo"}),
        stub("Org 2",
             link: "/government/organisations/bar",
             to_hash: {"title" => "Bar"})
      ]
      @presenter = OrganisationSetPresenter.new(@organisations)
    end

    should "include organisation fields" do
      results = @presenter.present["results"]
      assert_equal ["Foo", "Bar"], results.map { |r| r["title"] }
    end

    should "calculate the slug from the organisation's link" do
      results = @presenter.present["results"]
      assert_equal ["foo", "bar"], results.map { |r| r["slug"] }
    end
  end

end
