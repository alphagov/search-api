require "spec_helper"

RSpec.describe GovukIndex::PageTrafficJob do
  describe ".wait_until_processed" do
    before do
      allow(described_class).to receive(:sleep)
      allow(described_class).to receive(:active_jobs?).and_return(false)
      allow(Sidekiq::Queue)
        .to receive(:new)
        .with(described_class::QUEUE_NAME)
        .and_return([])
    end

    it "doesn't wait if there are no queued items and no active jobs" do
      described_class.wait_until_processed

      expect(described_class).not_to have_received(:sleep)
    end

    it "waits if there are queued items for this queue and job class" do
      job = Sidekiq::JobRecord.new({ "class" => described_class.name }.to_json,
                                   described_class::QUEUE_NAME)
      matching_jobs = [job, job]
      no_matching_jobs = []

      allow(Sidekiq::Queue)
        .to receive(:new)
        .with(described_class::QUEUE_NAME)
        .and_return(matching_jobs, matching_jobs, no_matching_jobs)

      described_class.wait_until_processed

      expect(described_class).to have_received(:sleep).with(1).exactly(2).times
    end

    it "waits if there are active jobs" do
      allow(described_class).to receive(:active_jobs?).and_return(true, true, false)

      described_class.wait_until_processed

      expect(described_class).to have_received(:sleep).with(1).exactly(2).times
    end

    it "raises an error if it waits longer than the max_timeout" do
      allow(described_class).to receive(:active_jobs?).and_return(true)
      allow(described_class).to receive(:sleep).and_call_original

      expect { described_class.wait_until_processed(max_timeout: 0.01) }
        .to raise_error(Timeout::Error)
    end
  end

  describe ".active_jobs?" do
    let(:key) { SecureRandom.base64(16) }
    let(:thread_id) { rand(1000..2000) }

    it "returns false if there are no Sidekiq jobs running" do
      allow(Sidekiq::WorkSet).to receive(:new).and_return([])

      expect(described_class.active_jobs?).to be(false)
    end

    it "returns false if Sidekiq jobs aren't for this job class or queue" do
      different_class_work = Sidekiq::Work.new(
        key,
        thread_id,
        { "queue" => described_class::QUEUE_NAME, "payload" => { "class" => "SomeOtherJob" } },
      )
      different_queue_work = Sidekiq::Work.new(
        key,
        thread_id,
        { "queue" => "different-queue", "payload" => { "class" => described_class.name } },
      )
      jobs = [[key, thread_id, different_class_work], [key, thread_id, different_queue_work]]
      allow(Sidekiq::WorkSet).to receive(:new).and_return(jobs)

      expect(described_class.active_jobs?).to be(false)
    end

    it "returns true if there are Sidekiq jobs running on this queue for this class" do
      work = Sidekiq::Work.new(
        key,
        thread_id,
        { "queue" => described_class::QUEUE_NAME, "payload" => { "class" => described_class.name } },
      )
      jobs = [[key, thread_id, work]]
      allow(Sidekiq::WorkSet).to receive(:new).and_return(jobs)

      expect(described_class.active_jobs?).to be(true)
    end
  end
end
