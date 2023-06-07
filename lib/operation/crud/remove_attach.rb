module Operation
  module Crud
    module RemoveAttach
      include Base

      def perform
        @model.send(form.attach_type).find(form.attach_id).purge
      end

      def setup!
        @model = with_caching { find_by_id }
      end
    end
  end
end
