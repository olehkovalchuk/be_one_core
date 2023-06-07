module Report
  module Base
    FIELDS = %i[id].freeze

     ALLOWED_DECORATORS = ['raw','xml','json','xls','csv'].freeze

    extend ActiveSupport::Concern

    class_methods do

      def get_fields(type)
        self.respond_to?("#{type}_fields") || get_default_fields
      end

      def get_default_fields
        FIELDS
      end

    end


    included do

      attr_reader :items

      def initialize(items)
        @items = items
        @generated = false
        @already_decorated = {}
        @data = []
      end

      ALLOWED_DECORATORS.each do |type|
        define_method( "to_#{type}" ) do
          generate(type) unless @generated
          decorate(type)
        end
      end

      private

      def decorate(type)
        if @already_decorated[type].blank?
          @already_decorated[type] = "Report::Decorator::#{type.capitalize}".constantize.report(@data, self.class.get_fields(type))
        end

        @already_decorated[type]
      end

      def generate(type)
        @generated = true
        mapper = ->(data,fields){ data.map { |item| fields.map { |field| item.try(:send, field) } } }
        @data = mapper.call(items,self.class.get_fields(type))
      end



    end


  end
end
