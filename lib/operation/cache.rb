module Operation
  # Operation caching methods
  module Cache
    protected

    # @!visibility public
    # Setting operation caching
    # @param key [Symbol]
    # @return depends on *key*
    #   * *:klass* (Class) cache store
    #   * *:enabled* (Boolean)
    #   * *:invalidate* invalidates cache based on params
    def cache(key = :klass)
      options = self.class.cache_options || {}

      case key
      when :klass
        options[:klass]
      when :enabled
        !!options[:enabled] && !params.dig(:caching, :disabled)
      when :invalidate
        if options.dig(:invalidate, :on).to_a.include?(self.class.name.demodulize.underscore.to_sym)
          Store.invalidate([self.class.model_klass] + options.dig(:invalidate, :dependencies).to_a)
        end
      end
    end

    def with_caching(**options, &block)
      result = if cache(:enabled)
        cache_options = options.merge(params.fetch(:caching, {}))
        key = cache_options[:cache_key] || cache_key

        cache_opts = {}.tap do |o|
          [:expires_in, :compress, :race_condition_ttl].each do |k|
            o[k] = cache_options[k] if cache_options.key?(k)
          end
        end

        cache.fetch(key, cache_opts) do
          yield
        end
      else
        yield
      end

      cache(:invalidate)
      result
    end

    def cache_key
      [Store.cache_key_prefix(self.class.model_klass.to_s), self.class.name.demodulize, Digest::MD5.hexdigest(params.sort.to_h.map{ |k,v| [k,v].join(':') }.join('&'))].join('_')
    end

    module Store
      extend self

      attr_accessor :list

      def push(model, store)
        self.list ||= {}
        self.list["#{model}"] ||= []
        self.list["#{model}"] << store unless self.list["#{model}"].include?(store)
      end

      def invalidate(models)
        return if self.list.nil?

        models.each do |model|
          return if self.list["#{model}"].empty?
          self.list["#{model}"].each do |cache_store|
            cache_store.delete_matched(cache_key_prefix("#{model}") + '*')
          end
        end
      end

      def cache_key_prefix(cls)
        [Rails.env.to_s, cls.underscore.downcase].join('_')
      end
    end
  end
end
