require_relative 'multilang_attributes'
require_relative 'check_coercion'
require_relative 'base/validation_class_methods'

module Validation
  # Adds default validation functionality.
  # Validation configuration happens in {Validation::Base::ValidationClassMethods}
  module Base
    attr_accessor :model_klass

    def self.included(base)
      super

      base.send(:include, Virtus.model(required: false))
      base.send(:include, Validation::MultilangAttributes)
      base.send(:include, ActiveModel::Validations)
      base.send(:include, ActiveModel::Validations::Callbacks)
      base.send(:include, Validation::CheckCoercion)

      base.extend ValidationClassMethods
    end
  end
end
