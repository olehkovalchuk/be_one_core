module Operation
  module Crud
    module List
      include Base

      def perform
        { total: @total, items: @model }
      end

      def setup!
        klass = self.class.model_klass.respond_to?(:not_deleted) ? self.class.model_klass.not_deleted : self.class.model_klass
        finder = with_caching { Finder.new(klass, params) }
        @model, @total = finder.get.to_a, finder.total
      end
    end
  end
end

