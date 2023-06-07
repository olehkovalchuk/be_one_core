# @private
class UniquenessValidator < ActiveRecord::Validations::UniquenessValidator
  def validate_each(record, attribute, value)
    # UniquenessValidator can't be used outside of ActiveRecord instances, here
    # we return the exact same error, unless the 'model' option is given.
    #

    if ! record.respond_to?(:model_klass) && ! record.class.ancestors.include?(ActiveRecord::Base)
      raise ArgumentError, "Unknown validator: 'UniquenessValidator'"

    # If we're inside an ActiveRecord class, and `model` isn't set, use the
    # default behaviour of the validator.
    #
    elsif ! record.model_klass
      super

    # Custom validator options. The validator can be called in any class, as
    # long as it includes `ActiveModel::Validations`. You can tell the validator
    # which ActiveRecord based class to check against, using the `model`
    # option. Also, if you are using a different attribute name, you can set the
    # correct one for the ActiveRecord class using the `attribute` option.
    #
    else
      @klass = record.model_klass

      record_org, attribute_org = record, attribute

      attribute = options[:attribute].to_sym if options[:attribute]
      new_record = record.try(:id) ? record.model_klass.find(record.id) : record.model_klass.new(attribute => value)
      Array.wrap(options[:scope]).each do |scope_item|
        new_record.send("#{scope_item}=", record.send(scope_item))
      end unless new_record.persisted?

      record = new_record

      super

      if record.errors.any?
        record_org.errors.add(attribute_org, :taken,
          options.except(:case_sensitive, :scope).merge(value: value))
      end
    end
  end
end
