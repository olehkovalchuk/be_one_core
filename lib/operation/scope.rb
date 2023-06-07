module Operation
  # Operation resource scoping methods
  module Scope
    private

    def with_resource_scope(&block)
      if RequestStore.store[:resource_scope]
        models = ActiveRecord::Base.descendants.select{|c| c.try(:use_resource_scoping) && !c.abstract_class}
        if models.empty?
          yield
        else
          yield_in_scope(models, models.shift) do
            yield
          end
        end
      else
        yield
      end
    end

    def yield_in_scope(models, model, &block)
      if models.empty?
        yield_in_model_scope(model) do
          yield
        end
      else
        yield_in_model_scope(model) do
          yield_in_scope(models, models.shift) do
            yield
          end
        end
      end
    end

    def yield_in_model_scope(model_klass, &block)
      wheres, joins = get_resource_scope(model_klass)
      if wheres.is_a?(Array) && !wheres[0].empty?
        model_klass.joins(joins).where(wheres).scoping do
          yield
        end
      else
        yield
      end
    end

    def get_resource_scope(model_klass)
      return nil unless model_klass.try(:use_resource_scoping)
      scope = RequestStore.store[:resource_scope] || {}
      return nil unless scope[:conditions].is_a?(Hash)

      res = []
      res_hash = {}
      joins = []
      _join__relations = []

      scope[:conditions].each do |k,v|
        case k
        when :path
          if BeOneAdmin.config.has_tree.include?(model_klass.table_name.sub(/^[a-zA-Z]+_/, '').singularize)
            _join__relations << model_klass.table_name
          else
            BeOneAdmin.config.has_tree.each do |tree_model|
              next unless parameters = model_klass.reflections[tree_model]
              _join__relations << parameters.options[:class_name].constantize.table_name
              joins << tree_model.to_sym
            end
          end

          next if _join__relations.empty?

          _join__relations.each do |relation|
            if scope[:with_children]
              res << "#{relation}.path ~ :path"
              res_hash[:path] = "#{v}.*"
            else
              res << "#{relation}.path = :path"
              res_hash[:path] = v
            end
          end

        end
      end
      [[res.join(' AND '), res_hash], joins]
    end


  end
end
