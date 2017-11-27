module ABVariants
  def with_ab_variants(&block)
    %w(A B).each do |variant|
      context "with '#{variant}' variant" do
        let(:ab_variant) { variant }
        module_eval(&block)
      end
    end
  end

  def get_with_variant path
    get path + "&ab_tests=synonyms:#{ab_variant}"
  end

  RSpec.configure { |c| c.extend self }
end
