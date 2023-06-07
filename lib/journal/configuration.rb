require_relative 'backtrace'

module Journal
  class Configuration
    attr_accessor :default_backend

    def initialize
      @backends = {
        fluentd: {
          host: Rails.application.secrets[:journal][:fluentd][:host],
          port: Rails.application.secrets[:journal][:fluentd][:port],
        },
        elasticsearch: {
          host: Rails.application.secrets[:journal][:elasticsearch][:host],
          port: Rails.application.secrets[:journal][:elasticsearch][:port],
        },
        filebeat: {
          path: Rails.application.secrets[:journal][:filebeat][:path],
          filename: Rails.application.secrets[:journal][:filebeat][:file_prefix],
          append_date_format: Rails.application.secrets[:journal][:filebeat][:append_date_format], # nil - do not append
          # Default filename: "log/kibana_stat-#{Time.zone.now.utc.strftime(config[:append_date_format])}.log"
        }
      }
      @default_backend = :fluentd
    end

    def configure_backends
      @backends.keys.each do |backend_name|
        backend_class = "Journal::Backend::#{backend_name.to_s.camelize}".constantize
        backend_class.configure if backend_class.respond_to?(:configure)
      end
    end

    def add_backend(name, config_options={})
      fail "Backend #{name} exists" if @backends.key?(name.to_sym)
      @backends[name.to_sym] = config_options
    end

    def enable_backtrace!
      at_exit { Journal::Backtrace.log_exceptions }
    end

    def method_missing(method_name, *args)
      backend_name = "#{method_name}".end_with?('=') && "#{method_name}"[0...-1].to_sym
      if args.is_a?(Array) && args.first.is_a?(Hash) && @backends.key?(backend_name)
        config_options = args.first.symbolize_keys
        @backends[backend_name].merge!(config_options)
        backend_class = "Journal::Backend::#{backend_name.to_s.camelize}".constantize
        backend_class.configure if backend_class.respond_to?(:configure)
      elsif @backends.key?(method_name)
        @backends[method_name]
      else
        super
      end
    end
  end
end
