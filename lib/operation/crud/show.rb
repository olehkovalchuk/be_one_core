module Operation
  module Crud
    module Show
      include Base

      def perform
        @model = find_by_id
      end
    end
  end
end
