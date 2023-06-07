module Journal
  module Repository

    class DynamicRepo
      include Elasticsearch::Persistence::Repository
    end

    @@pool ||= {}
    INDEX_TIME_FORMAT = '%Y-%m-%d'

    extend self

    def get(klass, type = '', time = nil)
      index_name, _ = _get_search_indice(klass, time)
      index_key = "get_#{type}_#{index_name}"

      @@pool.fetch(index_key) do |key|
        @@pool[key] = _get_new_repo(index_name, type, klass, true)
      end
    end

    def find(klass, id, options = {})
      index_name, _ = _get_search_indice(klass, options.delete(:time))
      index_key = "find_#{options[:type]}_#{index_name}"

      repository = @@pool.fetch(index_key) do |key|
        @@pool[key] = _get_new_repo(index_name, options.delete(:type).to_s, klass)
      end

      repository.find(id)
    end

    def search(klass, options = {})
      index_name, index_time_range = _get_search_indice(klass, options.delete(:time), false)
      index_key = "search_#{options[:type]}_#{index_name}"

      repository = @@pool.fetch(index_key) do |key|
        @@pool[key] = _get_new_repo(index_name, options.delete(:type).to_s, klass)
      end
      pp options
      query = QueryBuilder.new.build(options.delete(:query) || {}, index_time_range)

      case options.delete(:search_type)
      when 'count'
        repository.count(query)
      else
        options[:size] = 100 unless options[:size].present?
        repository.search(query, options ).map_with_hit(&:first)
      end
    end

    private

    def _get_new_repo(index_name, type, klass, do_mappings=false)
      client =  Elasticsearch::Client.new(url: "#{Journal.config.elasticsearch[:host]}:#{Journal.config.elasticsearch[:port]}", log: Rails.env.development?)
      repository = DynamicRepo.new(client: client, index_name: index_name, type: type, klass: klass ) 
      repository.settings number_of_shards: 1, number_of_replicas: 0 do
        mapping do
          klass.mappings.each do |field, values|
            indexes field, values
          end
        end
      end if do_mappings
      repository
    end

    def _get_search_indice(klass, time, exact_date=true)
      index_dates, data_range = if time.nil?
        ["*", {}]
      else
        dates = [time.to_date]
        range = {}

        unless exact_date
          utc_offset = Time.zone.utc_offset
          if utc_offset < 0
            dates.unshift(time.to_date - 1.day)
            range = {
              gte: ((dates.first.end_of_day + utc_offset.seconds).to_f * 1000.0).to_i,
              lt: ((dates.last.end_of_day + utc_offset.seconds).to_f * 1000.0).to_i
            }
          elsif utc_offset > 0
            dates.push(time.to_date + 1.day)
            range = {
              gte: ((dates.first.beginning_of_day + utc_offset.seconds).to_f * 1000.0).to_i,
              lt: ((dates.last.beginning_of_day + utc_offset.seconds).to_f * 1000.0).to_i
            }
          end
        end

        [dates.map{ |d| d.strftime(INDEX_TIME_FORMAT) }, range]
      end

      [Array.wrap(index_dates).map{ |d| "#{klass.name.demodulize.underscore}-#{Rails.env}-#{d}" }.join(','), data_range]
    end


    class QueryBuilder

      attr_reader :query

      def initialize
        @query = {}
      end

      def build(options, time_range={})
        unless options.empty?
          query = options.inject({m:[],f:[]}) do |hash,(k, v)|
            if(v.is_a? Array)
              hash[:f] << { "term": [[k,v]].to_h }
            else
              hash[:m] << { "match": { "#{k}": "#{v}" } }
            end
            hash
          end
          @query[:query] = {
            "bool": {
              "must": query[:m],
              "filter": query[:f],
            }
          }
        end
        unless time_range.empty?
          if @query.dig(:bool, :filter).is_a?(Array)
            @query[:bool][:filter].push(
              {
                "range": {
                  "created_at": time_range
                }
              }
            )
          else
            @query[:bool][:must].push(
              {
                "range": {
                  "created_at_ms": time_range
                }
              }
            )
          end
        end
        @query
      end

    end

  end
end
