module GovukIndex
  module IndexableContentKeys
    DEFAULTS = %w(body parts).freeze
    BY_FORMAT = {
      'licence'     => %w(licence_short_description licence_overview),
      'transaction' => %w(introductory_paragraph more_information),
    }.freeze

    def self.call(format)
      DEFAULTS + BY_FORMAT.fetch(format, [])
    end
  end
end
