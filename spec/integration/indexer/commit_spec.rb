require "spec_helper"

RSpec.describe "Commit" do
  describe "post /:index/commit" do
    it_behaves_like "govuk and detailed index protection", "/:index/commit", method: :post
    it_behaves_like "rejects unknown index", "/unknown_index/commit", method: :post
  end
end
