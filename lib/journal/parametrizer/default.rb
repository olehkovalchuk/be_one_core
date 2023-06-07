module Journal
  module Parametrizer
    module Default
      # Parametrize before writing to store
      # @param args [Hash] set of params to write to log
      def self.parametrize(args)
        args
      end
    end
  end
end
