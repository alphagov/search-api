module CoreExtensions
  module Time
    module ToString
      def to_s
        strftime("%Y-%m-%dT%H:%M:%S.%L%:z")
      end
    end
  end
end

class Time
  prepend CoreExtensions::Time::ToString
end
