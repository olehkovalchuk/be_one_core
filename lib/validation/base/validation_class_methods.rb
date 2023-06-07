module Validation
  module Base
    # Validation configuration
    module ValidationClassMethods
      # Creates default CRUD validations in scope of current validation class.
      # @option args [Array<Symbol>] :only ([]) list of inclusive CRUD operation. Available operation are [:index, :count, :show, :create, :update, :destroy]
      # @option args [Array<Symbol>] :except ([]) list of exclusive CRUD operation. Available operation are [:index, :count, :show, :create, :update, :destroy]
      def crudify(**args, &block)
        yield if block_given?

        default_methods = [:list, :index, :count, :show, :create, :update, :destroy,:read]
        default_methods.delete_if{ |m| !args[:only].include?(m) } if args[:only]
        default_methods.delete_if{ |m| args[:except].include?(m) } if args[:except]

        [args[:with]].flatten.compact.each do |m|
          default_methods << m
        end

        default_methods.each do |m|
          klass = case m
          when :show
            Class.new do
              include Validation::Base

              attribute :id, Integer
              attribute :scope, Proc
              validates :id, presence: true
            end
          when :create
            Class.new(self) do
            end
          when :exel
            Class.new do
              include Validation::Base
              attribute :filters, Array[Hash]
            end
          when :update
            Class.new(self) do
              attribute :id, Integer
              validates :id, presence: true
            end
          when :destroy
            Class.new do
              include Validation::Base

              attribute :id, Integer
              validates :id, presence: true
            end
          when :index
            Class.new do
              include Validation::Base

              attribute :page, Integer
              attribute :start, Integer
              attribute :limit, Integer
              attribute :query, Array
              attribute :filters, Array[Hash]
              attribute :sorters, Array[Hash]
              attribute :columns, Array[Hash]
              attribute :scope
            end
          when :count
            Class.new do
              include Validation::Base

              attribute :query, Array
              attribute :filters, Array[Hash]
              attribute :scope
            end

          when :habtm
            Class.new do
              include Validation::Base

              attribute :id, Integer
              attribute :relation, String
              attribute :includes, Array,default:[]
              validates :id, presence: true
              validate :relation_exist

              def relation_exist
                errors.add(:relation, :not_exist) unless self.model_klass.reflect_on_association( self.relation )
              end
            end
          when :habtm_update
            Class.new do
              include Validation::Base
              attribute :id, Integer
              attribute :ids, Array[Integer]
              attribute :relation, String

              validates :id, presence: true
              # validates :ids, presence: true
              validate :relation_exist

              def relation_exist
                errors.add(:relation, :not_exist) unless self.model_klass.reflect_on_association( self.relation )
              end
            end


          when :list
            Class.new do
              include Validation::Base

              attribute :page, Integer
              attribute :start, Integer
              attribute :limit, Integer
              attribute :query, Array
              attribute :filters, Hash
              attribute :sorters, Array[Hash]
              attribute :columns, Array[Hash]
              attribute :includes, Array
              attribute :scope
              attribute :current_admin
            end

          when :read
            Class.new do
              include Validation::Base

              attribute :id, Integer
              attribute :scope, Proc
              validates :id, presence: true
            end
          when :history
            Class.new do
              include Validation::Base

              attribute :id, Integer
              attribute :scope, Proc
              validates :id, presence: true
            end
          when :remove_attach
            Class.new do
              include Validation::Base

              attribute :id, Integer
              attribute :attach_id, Integer
              attribute :attach_type, String
              validates :id,:attach_id,:attach_type, presence: true
            end
          end
          self.parent.const_set("#{m}".classify, klass)
        end
      end
    end
  end
end
