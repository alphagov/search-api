module GovukIndex
  module MethodBuilder
    def delegate_to_payload(name, hash_key: name, convert_to_array: false)
      define_method name do
        value = payload[hash_key.to_s]
        return nil if value.nil? || value == ""

        if convert_to_array
          Array(value)
        else
          value
        end
      end
    end

    def set_payload_method(payload_method)
      define_method :payload do
        # Not defined as @payload as this conflicts with ivars in using classes
        @_payload ||= method(payload_method).call # rubocop:disable Naming/MemoizedInstanceVariableName
      end
    end
  end
end
