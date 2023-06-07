require 'digest/md5'
require_relative 'error'
require_relative 'finder'
require_relative 'cache'
require_relative 'scope'
require_relative 'base/operation_class_methods'
require_relative 'crud/count'
require_relative 'crud/create'
require_relative 'crud/destroy'
require_relative 'crud/list'
require_relative 'crud/read'
require_relative 'crud/update'
require_relative 'crud/index'
require_relative 'crud/habtm'
require_relative 'crud/habtm_update'
require_relative 'crud/remove_attach'

require_relative '../report/decorator'
require_relative '../report/base'
require_relative '../core_ext/hash_ext'

require_relative 'crud/exel'

module Operation
  # Adds default operation functionality.
  # Operation configuration happens in {Operation::Base::OperationClassMethods}
  module Base
    include Cache
    include Scope

    using HashExt

    RESERVED_PARAMS = {
      caching: Hash,
      decorator: nil
    }.freeze

    # validation form object
    attr_reader :form
    # operation model object
    attr_reader :model
    # operation params
    attr_reader :params
    # operation perform errors
    # attr_reader :errors
    # operation perform result
    attr_reader :result

    # Sets {model} attribute.
    # Creates validation {form} object.
    # Runs {#setup!}.
    # @param original_params [Hash] list of params for operation
    def initialize(original_params = {})
      @performed = false
      if original_params.is_a?(ActionController::Parameters)
        original_params = original_params.to_unsafe_h
      end
      @params = original_params.dup.with_indifferent_access
      @model = self.class.model_klass
      @errors = {}

      with_resource_scope do
        setup!
      end

      if validator_klass
        validator_klass.class_eval do
          RESERVED_PARAMS.each do |k, v|
            if v
              attribute k, v
            else
              attribute k
            end
          end
        end

        @form = validator_klass.new(params)
        @form.model_klass = self.class.model_klass
        @params = form.attributes.slice(*params.keys.map(&:to_sym)).with_indifferent_access
      end
    end

    # Main operation method. Runs {#perform} inside validation and caching
    # @option args [Boolean] :skip_validation Pass +true+ if validation should not be performed. Default is +false+
    # @return result of {#perform} method
    def process(args = {})
      @start = Time.zone.now.to_f
      with_validation(args) do
        with_resource_scope do
          begin
            @result = with_caching { perform }
          rescue Operation::Error => e
            if Rails.env.development?
              pp e.backtrace
              pp e.message
              pp e.errors
            end
            e.errors.each_pair do |k,v|
              add_error(k,v)
            end
            ::Journal.failure(
              file: [e.errors.to_json,@errors.to_json].to_json,
              file_type: "json",
              file_description: "Operation Errors",
              component: "#{self.class.name}",
              activity: "process",
              description: e.message,
              # args: form.attributes.reject{|k,v|  "#{k}" =~ /_base64_data/ || "#{k}" =~ /fields/ || "#{k}" =~ /files/ }.to_json,
              execution_time: (Time.zone.now.to_f - @start.to_f)
            )
            fail e if args[:raise_on_exceptions]
            @result = nil
          rescue => e
            if Rails.env.development?
              pp e.backtrace
              pp e.message
            end

            ::Journal.failure(
              file: e.backtrace.join("\n"),
              file_type: "raw",
              file_description: "Operation Exception",
              component: "#{self.class.name}",
              activity: "process",
              description: e.message,
              # args: (form ? form.attributes.reject{|k,v|  "#{k}" =~ /_base64_data/ || "#{k}" =~ /fields/ || "#{k}" =~ /files/} : {}).except_nested_key("io").to_json,
              execution_time: (Time.zone.now.to_f - @start.to_f)
            )
            fail e if args[:raise_on_exceptions]
            @result = nil
            add_error(500, 'Internal server error') if @errors.empty?
          end
          @performed = true
          result
        end
      end
    end

    # Runs {#process}
    # @return {model} object
    def run
      process
      model
    end

    # Runs {#process}
    # @return {form} object
    def present
      process
      form
    end

    def decorate
      decorator_klass ? decorator_klass.decorate(self) : result
    end

    # Basic setup of operation. By default does nothing. This can be redefined in operation
    def setup!
    end

    # Operation body
    # @return operation result
    def perform
    end

    # @private
    def self.included(base)
      base.extend OperationClassMethods
    end

    # @return {Boolean} `true` if validation was passed and `perform` method run. `false` otherwise
    def performed?
      @performed
    end

    # @return {Boolean} `true` if operation performed with no errors. `false` otherwise
    def success?
      performed? && errors.empty?
    end

    # Add error of performing operation
    # @param code [String] error code. Should be unique in course of performing operation
    # @param message [String] error message
    # @return {String} added error message
    def add_error(code, message)
      @errors[code] = message
    end

    def add_error!(code, message = nil)
      message = if message.kind_of?(Hash)
        I18n.t("errors.#{self.class.model_klass.name.underscore.gsub("/","_")}.#{code}",message)
      elsif message.nil?
        I18n.t("errors.#{self.class.model_klass.name.underscore.gsub("/","_")}.#{code}")
      else
        message
      end
      add_error(code, message)
      fail Operation::Error.new( @errors )
    end

    def errors
      @errors.merge form.errors.messages
    end

    protected

    def decorator_klass
      params[:decorator] || self.class.decorator
    end

    def validator_klass
      self.class.validator || (self.class.model_klass && ("#{self.class.model_klass}Validation::#{self.class.name.demodulize}".safe_constantize || "#{self.class.model_klass}Validation::Base".safe_constantize))
    end

    def callback_klass
      self.class.callback || "#{self.class.model_klass}Action".safe_constantize
    end

    def trigger(callback_name, *args)
      if callback_klass && callback_klass.respond_to?(callback_name)
        callback_klass.send(callback_name, *args)
      end
    end

    def with_validation(args = {}, &block)
      return false unless block_given?
      start = Time.zone.now.to_f
      if !args[:skip_validation] && form && !form.valid?
        ::Journal.failure(
          file: form.errors.to_json,
          file_type: "json",
          file_description: "Validation Errors",
          component: "#{self.class.name}",
          activity: "with_validation",
          description: "Invalid params passed to #{self.class.name}" ,
          # args: form.attributes.reject{|k,v| "#{k}" =~ /_base64_data/ || "#{k}" =~ /fields/ || "#{k}" =~ /files/ }.to_json,
          execution_time: (Time.zone.now.to_f - start.to_f)
        )
        if Rails.env.development?
          pp form.class
          pp form.errors
        end
        return false
      end

      yield
    end

    def with_transaction(&block)
      ActiveRecord::Base.transaction { yield || false }
    end

    def find_by_id
      find_by(:id)
    end

    def find_by( field, raise_on_exception = true )
      return nil unless params[field]
      relation = self.class.model_klass.where(field =>  params[field])
      if params[:scope] && params[:scope].is_a?(Proc)
        relation = params[:scope].(relation)
      end
      raise_on_exception ? relation.take! : relation.take
    end

    def form_attributes
      form.attributes.slice(*(params.keys.map(&:to_sym) - RESERVED_PARAMS.keys))
    end

    def set_model_attributes
      form_attributes.each do |k, v|
        model.send("#{k}=", v) if model.respond_to?(k)
      end
    end

  end
end
