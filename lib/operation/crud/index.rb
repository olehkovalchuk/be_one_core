module Operation
  module Crud
    module Index
      include Base

      def perform
        @model
      end

      def setup!
        @model = Finder.new(self.class.model_klass, params).get
      end
    end
  end
end
