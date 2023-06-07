module Journal
  class Record
    include Virtus.model
    include ActiveModel::Serialization
    attribute :id, String
    attribute :has_parent, Boolean, default: true
    attribute :parent_field, String, default: 'request_id'
    attribute :request_id, String
    attribute :request_type, String, default: 'default'
    attribute :status, Integer
    attribute :component, String
    attribute :activity, String
    attribute :args, String
    attribute :description, String
    attribute :user_id, Integer
    attribute :user_ip, String
    attribute :user_country, String
    attribute :user_type, String # user: 1, admin: 2
    attribute :user_agent, String
    attribute :user_login, String
    attribute :user_token, String
    attribute :system_id, Integer
    attribute :session_id, String
    attribute :core_ip, String
    attribute :has_file, Boolean, default: false
    attribute :client_ip, String
    attribute :client_country, String
    attribute :client_version, String
    attribute :server_version, String
    attribute :execution_time, Float
    attribute :created_at, DateTime
    attribute :created_at_ms, Float
    attribute :http_method, String
    attribute :http_format, String

    class << self
      def push(args)
        Rails.logger.info "."* 100
        Rails.logger.info RequestStore.store[:journal_parametrizer].inspect
        args = args.dup.symbolize_keys
        return if (Rails.env.test? || Rails.env.bamboo?) && !args.delete(:force_push)
        backend = args.delete(:backend) || "Journal::Backend::#{Journal.config.default_backend.to_s.camelize}".constantize
        parametrizer = args.delete(:parametrizer) || RequestStore.store[:journal_parametrizer] || Journal::Parametrizer::Default
        args = parametrizer.parametrize(args)
        args[:user_country] = "ZZZ" unless args[:user_country].present?
        args[:component] = "#{args[:component]}".gsub("/","_")
        args[:activity] = "#{args[:activity]}".gsub("/","_")
        if Rails.env.development?
          Rails.logger.info(args[:description])
          Rails.logger.info(args[:file])
        end
        backend.save(args)
      end

      def search(params = {})
        Journal::Repository.search(self, params)
      rescue Elasticsearch::Persistence::Repository::DocumentNotFound, Elasticsearch::Transport::Transport::Errors::NotFound
        []
      end

      def count(params = {})
        search(params.merge(search_type: 'count'))
      end

      def find(id)
        search(query: {id: id}).first
      end

      def mappings
        {
          id: { type: 'text' },
          has_parent: { type: 'boolean' },
          request_id: { type: 'text' },
          status: { type: 'integer' },
          component: { type: 'text' },
          activity: { type: 'text' },
          user_id: { type: 'integer' },
          user_ip: { type: 'text' },
          user_country: { type: 'text' },
          user_type: { type: 'text' },
          user_login: { type: 'text' },
          user_token: { type: 'text' },
          system_id: { type: 'integer' },
          session_id: { type: 'text' },
          execution_time: { type: 'float' },
          description: { index: 'no' },
          args: { index: 'no' },
          record_id: { type: 'text' },
          created_at: { type: 'date' },
          created_at_ms: { type: 'float' },
          http_method: { type: 'text' },
          http_format: { type: 'text' },
        }
      end

      def model_name
        Struct.new(:human).new(self.name)
      end

      def attribute_names
        self.attribute_set.map(&:name)
      end
    end

    def files
      has_file ? Journal::File.search(query: { record_id: id, created_at: created_at }) : []
    end
  end
end
