require "spec_helper"

RSpec.describe "Commit" do
  describe "post /:index/commit" do
    it_behaves_like "govuk index protection", "/govuk/commit", method: :post
  end
end
