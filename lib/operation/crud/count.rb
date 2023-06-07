module Operation
  module Crud
    module Count
      include Base

      def perform
        @model
      end

      def setup!
        @model = with_caching { Finder.new(self.class.model_klass, params).get.count.to_i }
      end
    end
  end
end
