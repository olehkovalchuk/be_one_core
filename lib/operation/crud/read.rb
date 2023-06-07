module Operation
  module Crud
    module Read
      include Base

      def perform
        @model
      end

      def setup!
        @model = with_caching { find_by_id }
      end
    end
  end
end
