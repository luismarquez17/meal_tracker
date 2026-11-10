# Compatibility patch for ActiveSupport JSON encoding
module ActiveSupport
  module JSON
    module Encoding
      class << self
        def stringify(value)
          ::JSON.generate(value)
        rescue ArgumentError
          ::JSON.generate(value, quirks_mode: true)
        end
      end
    end
  end
end
