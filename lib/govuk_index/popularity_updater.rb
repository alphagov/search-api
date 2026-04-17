module GovukIndex
  class PopularityUpdater < Updater
    def self.job
      PopularityJob
    end
  end
end
