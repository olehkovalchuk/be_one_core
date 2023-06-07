module Journal
  module Backend
    class Elasticsearch
      extend Base

      def self.save(args)
        refresh = !!args.delete(:refresh_index)

        record = get_record(args)
        Journal::Repository.get(record.class, record.request_type, record.created_at).save(record, refresh: refresh)

        get_files(record, args).each do |file|
          Journal::Repository.get(file.class, file.content_type, record.created_at).save(file, refresh: refresh)
        end

        record
      end
    end
  end
end
