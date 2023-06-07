module Operation
  module Crud
    module Habtm
      include Base

      def perform
        klass = self.class.model_klass.reflect_on_association(form.relation).klass
        all = klass.includes(form.includes).all
        model_relations = @model.send(form.relation).to_a
        exists = all.select{ |item| model_relations.include?( item ) }
        available = all.select{ |item| !model_relations.include?( item ) }
        {available: available, exists: exists}
      end

      def setup!
        @model = find_by_id
      end

    end
  end
end
