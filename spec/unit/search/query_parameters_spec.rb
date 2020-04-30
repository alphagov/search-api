require "spec_helper"

RSpec.describe Search::QueryParameters do
  context "quoted_search_phrase?" do
    it "return false if query isn't quote enclosed" do
      params = described_class.new(query: "my query")
      expect(false).to eq(params.quoted_search_phrase?)
    end

    it "return false if entire query isn't quote enclosed" do
      params = described_class.new(query: %(This is "part of my" query))
      expect(false).to eq(params.quoted_search_phrase?)
    end

    it "return false if query doesn't have ending quotes" do
      params = described_class.new(query: %("unclosed quotes))
      expect(false).to eq(params.quoted_search_phrase?)
    end

    it "return false if query doesn't have starting quotes" do
      params = described_class.new(query: %(unclosed quotes"))
      expect(false).to eq(params.quoted_search_phrase?)
    end

    it "return true if query enclosed with quotes" do
      params = described_class.new(query: %("phrase enclosed with quotes"))
      expect(true).to eq(params.quoted_search_phrase?)
    end

    it "return false if enclosed with quotes but has intervening quotes" do
      params = described_class.new(query: %("phrase enclosed with quotes and "quotes" in the middle))
      expect(false).to eq(params.quoted_search_phrase?)
    end

    it "return true if query enclosed with quotes but with leading whitespace" do
      params = described_class.new(query: %(  \t  "phrase enclosed with quotes"))
      expect(true).to eq(params.quoted_search_phrase?)
    end

    it "return true if query enclosed with quotes but with trailing whitespace" do
      params = described_class.new(query: %("phrase enclosed with quotes"  \t  ))
      expect(true).to eq(params.quoted_search_phrase?)
    end

    it "return false if the query is nil" do
      params = described_class.new
      expect(false).to eq(params.quoted_search_phrase?)
    end
  end

  context "query" do
    it "return the query if there are no enclosing quotes" do
      params = described_class.new(query: %(my query))
      expect(%(my query)).to eq(params.query)
    end

    it "return the query with enclosing quotes if there are embedded quotes" do
      params = described_class.new(query: %("Enclosing quotes but with "embedded" quotes"))
      expect(%("Enclosing quotes but with "embedded" quotes")).to eq(params.query)
    end

    it "not strip leading and trailing whitespace if phrase is enclosed in quotes" do
      params = described_class.new(query: %(  \t "Enclosing quotes"\t  ))
      expect(%(  \t "Enclosing quotes"\t  )).to eq(params.query)
    end

    it "not strip leading and trailing whitespace if not enclosed in quotes" do
      params = described_class.new(query: %(  my query  ))
      expect(%(  my query  )).to eq(params.query)
    end

    it "not strip leading and trailing whitespace if phrase contains embedded quotes" do
      params = described_class.new(query: %(  \t"Enclosing quotes but with "embedded" quotes"  ))
      expect(%(  \t"Enclosing quotes but with "embedded" quotes"  )).to eq(params.query)
    end
  end

  describe "#model_variant" do
    allowed_variants = %w[foo bar baz]
    disallowed_variants = %w[X Y Z]

    before { ENV["TENSORFLOW_SAGEMAKER_VARIANTS"] = allowed_variants.join(",") }
    after { ENV["TENSORFLOW_SAGEMAKER_VARIANTS"] = nil }
    subject { described_class.new(ab_tests: ab_tests).model_variant }

    allowed_variants.each do |variant|
      context "given allowed variant" do
        let(:ab_tests) { { mv: variant } }
        it { is_expected.to eq variant }
      end
    end
    disallowed_variants.each do |variant|
      context "given a disallowed variant" do
        let(:ab_tests) { { mv: variant } }
        it { is_expected.to be_nil }
      end
    end
  end
end
