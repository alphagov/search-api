module GovukIndex
  class SupertypeUpdater < Updater
    def self.job
      SupertypeJob
    end
  end
end
