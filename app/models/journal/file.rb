module Journal
  class File
    include Virtus.model

    attribute :id, String
    attribute :file_description, String
    attribute :request_type, String, default: 'default'
    attribute :content, String
    attribute :content_type, String
    attribute :record_id, String
    attribute :created_at, DateTime
    attribute :created_at_ms, Float

    class << self
      def search(params = {})
        params[:query].symbolize_keys! if params[:query]
        if params.dig(:query, :created_at)
          params[:time] = params[:query].delete(:created_at)
        end
        Journal::Repository.search(self, params)
      rescue Elasticsearch::Persistence::Repository::DocumentNotFound, Elasticsearch::Transport::Transport::Errors::NotFound
        []
      end

      def count(params = {})
        search(params.merge(search_type: 'count'))
      end

      def mappings
        {
          id: { type: 'text' },
          content: { index: 'no' },
          record_id: { type: 'text' },
          created_at: { type: 'date' },
          created_at_ms: { type: 'float' }
        }
      end

      def model_name
        Struct.new(:human).new(self.name)
      end

      def attribute_names
        self.attribute_set.map(&:name)
      end
    end
  end
end
