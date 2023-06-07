module Validation
  module CheckCoercion
    def self.included(base)
      base.class_eval do
        alias_method :active_model_validation, :valid?
        alias_method :valid?, :valid_with_coercion
      end
    end

    def valid_with_coercion(context = nil)

      result = active_model_validation(context)
      coerced = true

      attribute_set.instance_variable_get('@index').select{|k,_v| k.is_a?(Symbol)}.each do |k, v|
        output = send(k)
        coercion_res = v.value_coerced?(output) || (!v.required? && output.nil?)

        unless coercion_res
          errors.add(k, :invalid)
          coerced = false
        end
      end

      result && coerced
    end
  end
end
