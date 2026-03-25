module EsExtract
  module Suggest
    module_function

    def entries(suggest, name)
      Array(suggest[name.to_s])
    end

    def options(entry)
      Array(entry["options"])
    end
  end
end