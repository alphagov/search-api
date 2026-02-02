require "spec_helper"
require "rake"

RSpec.describe "duplicates", "RakeTest" do
  let(:fake_duplicates) do
    [
      {
        content_id: "aaa-111",
        documents: [
          { "title" => "T1", "link" => "/a1", "updated_at" => "2020-01-01" },
          { "title" => "T2", "link" => "/a2" },
        ],
      },
      {
        content_id: "bbb-222",
        documents: [
          { "title" => "X1", "link" => "/x1", "updated_at" => "2022-05-05" },
          { "title" => "X2", "link" => "/x2", "updated_at" => "2025-05-05" },
        ],
      },
    ]
  end
  let(:index) { "government" }

  before do
    Rake::Task[task_name].reenable
    allow(Search::DuplicateFinder)
      .to receive(:new)
            .with(index:)
            .and_return(double(find_duplicates: fake_duplicates))
  end

  describe "duplicates:find" do
    let(:task_name) { "duplicates:find" }

    it "prints duplicate sets in the expected format" do
      output = capture_stdout { Rake::Task[task_name].invoke(index) }

      expect(output).to include("Content_id: aaa-111")
      expect(output).to include("  T1 /a1 2020-01-01")
      expect(output).to include("  T2 /a2 ")
      expect(output).to include("Content_id: bbb-222")
      expect(output).to include("  X1 /x1 2022-05-05")
      expect(output).to include("  X2 /x2 2025-05-05")
    end
  end

  describe "duplicates:remove" do
    let(:task_name) { "duplicates:remove" }
    let(:duplicate_remover) { instance_double(Search::DuplicateRemover, remove_duplicates: nil) }
    before do
      allow(Search::DuplicateRemover)
        .to receive(:new)
              .with(index:)
              .and_return(duplicate_remover)
    end
    describe "there are duplicates" do
      it "removes duplicates" do
        Rake::Task[task_name].invoke(index)
        expect(duplicate_remover).to have_received(:remove_duplicates).with(duplicates: fake_duplicates).once
      end
    end
    describe "there are no duplicates" do
      let(:fake_duplicates) { [] }
      it "does not remove duplicates" do
        output = capture_stdout { Rake::Task[task_name].invoke(index) }
        expect(output).to eq("No duplicates found\n")
      end
    end
  end

  def capture_stdout
    old = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old
  end
end
