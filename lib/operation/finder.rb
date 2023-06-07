module Operation
  class Finder
    AVAILABLE_OPERATIONS = %w[eq gt lt gteq lteq matches].freeze
    OPERATION_ALIASES = { 'gte' => 'gteq', 'lte' => 'lteq' }.freeze
    DEFAULT_OPERATION = 'eq'.freeze

    attr_reader :model, :columns, :params

    def initialize(model, params)
      @model = model
      @columns = params.delete(:columns) || []
      @params = params
    end

    def get
      @get ||= apply_offset(apply_sorting(relation, params[:sorters]), params)
    end

    def total
      @total ||= relation.count
    end

    def attr_type(attr_name)
      return :string unless @model.columns_hash[attr_name]
      @model.columns_hash[attr_name].array? ? :array : @model.columns_hash[attr_name].type
    end

    def relation
      return @relation if defined? @relation
      @relation = @model.all
      @relation = @relation.includes(params[:includes]) if params[:includes]
      @relation = @relation.where(parent_id: 1) if params[:only_roots]
      @relation = @relation.where(predicates_for_and_conditions(params[:filters])) if params[:filters]

      @relation = extend_relation_with_scope(@relation, params[:scope])
    end

    def predicates_for_and_conditions(conditions)
      conditions = JSON.load(conditions) if conditions.kind_of?(String)
      return if conditions.empty?

      predicates = conditions.each_with_object([]) do |(attr, value), array|
        attr = attr.to_s

        if (operation = attr.match(".*_(#{(AVAILABLE_OPERATIONS + OPERATION_ALIASES.keys).join('|')})\\z").try(:[], 1))
          attr = attr.gsub(/_(#{operation})\z/, '')
          operation = OPERATION_ALIASES[operation] || operation
        end

        array << updated_predecate(attr, value, operation) if @model.column_names.include?(attr)
      end

      # join them by AND
      predicates[1..-1].inject(predicates.first) { |r, p| r.and(p) }
    end

    def update_predecate_for_boolean(table, value)
      table.eq(value)
    end

    def update_predecate_for_string(table, value, operation)
      case operation
      when 'eq'
        table.eq(value)
      else
        table.matches("%#{value}%")
      end
    end

    def update_predecate_for_json(table, value, operation)
      key = value.keys[0]
      value = value[key]
      if (_operation = key.match(".*_(#{(AVAILABLE_OPERATIONS + OPERATION_ALIASES.keys).join('|')})\\z").try(:[], 1))
        key = key.gsub(/_(#{_operation})\z/, '')
      end


      arel_node = Arel::Nodes::InfixOperation.new('->>', table, Arel::Nodes::Quoted.new(key))

      case OPERATION_ALIASES[_operation] || operation
      when 'eq'
        arel_node.eq(value)
      else
        arel_node.matches("%#{value}%")
      end
    end

    def update_predecate_for_array(table, value)
      if value.is_a?(Array)
        Arel::Nodes::JsonbAtArrow.new(table, Arel::Nodes.build_quoted(value, table))
      else
        Arel::Nodes::Equality.new(Arel::Nodes::Quoted.new(value), Arel::Nodes::NamedFunction.new('ANY', [table]))
      end
    end

    def update_predecate_for_datetime(table, value, operation)
      operation ||= DEFAULT_OPERATION

      case operation
      when 'eq'
        table.lteq(value.end_of_day).and(table.gteq(value.beginning_of_day))
      when 'gt'
        table.gt(value.end_of_day)
      when 'lt'
        table.lt(value.beginning_of_day)
      when 'gteq'
        table.gteq(value.beginning_of_day)
      when 'lteq'
        table.lteq(value.end_of_day)
      end
    end

    def update_predecate_for_rest(table, value, operation)
      operation ||= DEFAULT_OPERATION

      if AVAILABLE_OPERATIONS.include?(operation)
        value = "%#{value}%" if operation == 'matches'
        operation = :in if value.kind_of?(Array)
        table.send(operation, value)
      else
        Rails.logger.warn("Illegal filter operator: #{operation}")
        table
      end
    end

    protected

    # Addresses the n+1 query problem
    # Returns updated relation
    def fix_nplus1_problem(relation, columns)
      columns.reduce(relation) do |rel, c|
        assoc, method = c[:name].split('__')
        method ? rel.includes(assoc.to_sym).references(assoc.to_sym) : rel
      end
    end

    def apply_sorting(relation, sorters)
      return relation if sorters.blank?

      sorters = Array.new(sorters)
      relation = relation.reorder('') # reset eventual default_scope ordering

      sorters.reduce(relation) do |_rel, sorter|
        key = sorter.keys.first
        next unless model.column_names.include? key.to_s
        relation = relation.order("#{@model.table_name}.#{key} #{sorter[key].to_s.downcase}")
      end

      relation
    end

    def apply_offset(relation, params)
      return relation if params[:limit].blank?
      relation.offset(params[:start]).limit(params[:limit])
    end

    private

    def updated_predecate(attr, value, operation)
      case attr_type(attr)
      when :datetime
        update_predecate_for_datetime(@model.arel_table[attr], value.to_date, operation)
      when :string, :text
        update_predecate_for_string(@model.arel_table[attr], value, operation)
      when :float
        update_predecate_for_rest(@model.arel_table[attr], value.to_f, operation)
      when :integer
        update_predecate_for_rest(@model.arel_table[attr], value.kind_of?(Array) ? value.wrap.map(&:to_i) : value.to_i, operation)
      when :boolean
        update_predecate_for_boolean(@model.arel_table[attr], value)
      when :date
        update_predecate_for_rest(@model.arel_table[attr], value.to_date, operation)
      when :jsonb
        update_predecate_for_json(@model.arel_table[attr], value, operation)
      when :array
        update_predecate_for_array(@model.arel_table[attr], value)
      else
        update_predecate_for_rest(@model.arel_table[attr],  value, operation)
      end
    end

    def extend_relation_with_scope(relation, scope)
      case scope
      when Proc
        scope.call(relation)
      when :main
        relation.send(scope)
      when Hash
        relation.where(scope)
      when NilClass
        relation
      else
        raise ArgumentError, "Expected scope to be a Proc or a Hash, got #{scope.class}"
      end
    end
  end
end
