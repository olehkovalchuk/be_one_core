module Operation
  module Base
    # Operation configuration
    module OperationClassMethods
      # operation decorator class
      attr_accessor :decorator
      # operation validator class
      attr_accessor :validator
      # operation callback class
      attr_accessor :callback
      # operation model class
      attr_accessor :model_klass
      # operation caching options
      attr_accessor :cache_options

      # Shorthand for calling {::new} and {#process}.
      # @param params [Hash] argument for {::new} method
      def call(params = {})
        new(params).process
      end

      # Creates default CRUD operations in scope of current operation class.
      # @option args [Array<Symbol>] :only ([]) list of inclusive CRUD operation. Available operation are [:index, :count, :show, :create, :update, :destroy]
      # @option args [Array<Symbol>] :except ([]) list of exclusive CRUD operation. Available operation are [:index, :count, :show, :create, :update, :destroy]
      # @option args [Hash] :cache (nil) caching settings for operation. See {#cache} for details
      def crudify(**args, &block)
        yield

        default_methods = [
          :list,
          :count,
          :read,
          :create,
          :update,
          :index,
          :destroy
        ]

        available_exentions = [
          :habtm,
          :habtm_update,
          :exel,
          :remove_attach,
        ]

        default_methods.delete_if{ |m| !args[:only].include?(m) } if args[:only]
        default_methods.delete_if{ |m| args[:except].include?(m) } if args[:except]
        [args[:with]].flatten.compact.each do |m|
          default_methods << "#{m}".to_sym if available_exentions.include? "#{m}".to_sym
        end
        default_methods.each do |m|
          op = m.to_s.classify
          klass = Class.new(self) do
            include "Operation::Crud::#{op}".constantize
            if args[:cache]
              cache(
                enabled: !!args.dig(:cache, m, :enabled),
                klass: args.dig(:cache, m, :klass),
                invalidate: {
                  on: args.dig(:invalidate, :on).to_a,
                  dependencies: args.dig(:invalidate, :dependencies).to_a
                }
              )
            end
          end
          self.parent.const_set op, klass
        end
      end

      # @param klass (Class) model class for operation
      def model_name(klass)
        self.model_klass = klass
      end

      # @param klass (Class) decoration class for operation
      def decorate_with(klass)
        self.decorator = klass
      end

      # @param klass (Class) validation class for operation
      def validate_with(klass)
        self.validator = klass
      end

      # @param klass (Class) callback class for operation
      def callback_with(klass)
        self.callback = klass
      end

      # Set cache options for operation
      # @param klass [Class] cache store. Default is +Rails.cache+
      # @param enabled [Boolean] default is +false+
      # @param invalidate [Hash] invalidation params
      #   * *:on* list of operations for invalidation. Default is [:create, :update, :destroy]
      #   * *:dependencies* list of dependencies for invalidation. Default is []
      def cache(klass: nil, enabled: false, invalidate: {})
        klass ||= Rails.cache

        self.cache_options = {
          klass: klass,
          enabled: enabled,
          invalidate: {
            on: ([:create, :update, :destroy] + invalidate[:on].to_a.map{ |x| x.to_s.underscore.to_sym }).uniq,
            dependencies: invalidate[:dependencies].to_a
          }
        }
        Cache::Store.push(self.model_klass, klass) if enabled
      end

      # @private
      def inherited(subclass)
        subclass.model_name(self.model_klass)
      end
    end
  end
end
