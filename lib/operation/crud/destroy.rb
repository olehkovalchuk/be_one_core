module Operation
  module Crud
    module Destroy
      include Base

      def perform
        with_transaction do
          old_model = model.dup
          add_error!(:undeletable, "Model cant be deleted") if model.respond_to?(:undeletable) && model.undeletable
          trigger :before_destroy, model
          begin
            result = model.respond_to?(:deleted) ? model.update(deleted: true) : model.destroy!
          rescue ActiveRecord::RecordNotDestroyed => e
            add_error!(:cant_destroy,"Cant be destoyed")
          end

          trigger :after_destroy, old_model

          result
        end
      end

      def setup!
        @model = self.class.model_klass.where(id: params[:id]).take
      end
    end
  end
end
