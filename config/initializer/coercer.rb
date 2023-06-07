require 'support/type_lookup'

module Coercible

  # A module that adds type lookup to a class
  module TypeLookup
    def determine_type_from_primitive(primitive)
      type = primitive == ActiveSupport::TimeWithZone ? Coercible::Coercer::DateTime : nil

      descendants.reverse_each do |descendant|
        descendant_primitive = descendant.primitive
        next unless primitive <= descendant_primitive
        type = descendant if type.nil? or type.primitive > descendant_primitive
      end unless type

      type
    end
  end
end

require 'coercible/coercer/date_time'
module Coercible
  class Coercer

    # Coerce DateTime values
    class DateTime < Object
      primitive ::DateTime

      include TimeCoercions

      # Passthrough the value
      #
      # @example
      #   coercer[DateTime].to_datetime(datetime)  # => DateTime object
      #
      # @param [DateTime] value
      #
      # @return [Date]
      #
      # @api public
      def to_datetime(value)
        value.to_datetime
      end

    end # class DateTime

  end # class Coercer
end # module Coercible

require 'coercible/coercer/string'
module Coercible
  class Coercer

    # Coerce String values
    class String < Object
      # Coerce given value to Time
      #
      # @example
      #   coercer[String].to_time(string)  # => Time object
      #
      # @param [String] value
      #
      # @return [Time]
      #
      # @api public
      def to_time(value)
        value.to_time
      rescue ArgumentError
        raise_unsupported_coercion(value, __method__)
      end

      # Coerce given value to Date
      #
      # @example
      #   coercer[String].to_date(string)  # => Date object
      #
      # @param [String] value
      #
      # @return [Date]
      #
      # @api public
      def to_date(value)
        value.to_date
      rescue ArgumentError
        raise_unsupported_coercion(value, __method__)
      end

      # Coerce given value to DateTime
      #
      # @example
      #   coercer[String].to_datetime(string)  # => DateTime object
      #
      # @param [String] value
      #
      # @return [DateTime]
      #
      # @api public
      def to_datetime(value)
        value.to_datetime
      rescue ArgumentError
        raise_unsupported_coercion(value, __method__)
      end
    end
  end
end
