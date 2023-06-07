module Validation
  module MultilangAttributes
    def initialize(params)
      params = prepare(params)
      super(params)
    end

    def self.included(base)
      super

      base.extend MultilangAttributeClassMethods
    end

    module MultilangAttributeClassMethods
      attr_accessor :multilang_attributes

      # Adds multilang attribute Hash[String => *type*] to validation
      # @param name [String, Symbol] attribute name
      # @param type [Class] attribute type
      def multilang_attribute(name, type=String)
        self.multilang_attributes ||= []
        self.multilang_attributes << name
        
        attribute "#{name}", Hash[String => type]
        before_validation do |params|
          params.send(name).delete_if{ |_,v| v.blank? }
        end
      end

      def inherited(subclass)
        super

        self.multilang_attributes.each do |multilang_attr|
          subclass.multilang_attribute(multilang_attr)
        end unless self.multilang_attributes.blank?
      end
    end
    def method_missing( method_name, *args )
      if /_multilang_/ =~ method_name.to_s
        attribute_name = method_name.to_s.split("_multilang").first
        errors.add(attribute_name, :blank) unless send(attribute_name).values.reject(&:blank?).any?
      else
        super
      end
    end
    private

    def prepare(params)
      unless self.class.multilang_attributes.blank?
        self.class.multilang_attributes.each do |name|
          next unless I18n.available_locales.map{ |l| params.key?("#{name}_#{l}") }.any?
          params[name] = I18n.available_locales.map{ |l| [l, params.delete("#{name}_#{l}")] }.to_h.reject{ |k,v| v.nil? }
        end
      end

      params
    end
  end
end
