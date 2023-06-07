module Operation
  module Crud
    module HabtmUpdate
      include Base

      def perform
        with_transaction do
          relation = self.class.model_klass.reflections[form.relation]
          relation_key  = :id #relation.options[:association_foreign_key] || :id
          items = self.class.model_klass.reflections[form.relation].klass.where( relation_key => [params[:ids]].flatten).all
          @model.send("#{form.relation}=",items)
          trigger :after_update, @model, form
          true
        end
      end

      def setup!
        @model = find_by_id
      end

    end
  end
end
