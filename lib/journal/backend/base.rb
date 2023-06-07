module Journal
  module Backend
    module Base
      extend self

      def get_record(args)
        args[:args] = args[:args].to_unsafe_h if args[:args].is_a?(ActionController::Parameters)
        if args[:args].is_a?(Hash)
          args[:args].keys.each do |k|
            args[:args][k] = args[:args][k].original_filename.to_s if args[:args][k].is_a?(ActionDispatch::Http::UploadedFile)
          end
          args[:args] = filter_parameters(args[:args])
        end

        args[:args] = args[:args].to_json unless args[:args].is_a?(String)

        record = Journal::Record.new(args)
        record.id = SecureRandom.uuid
        record.created_at ||= Time.zone.now.utc
        record.created_at_ms = record.created_at.to_f
        record.has_file = !!args[:file] || (args[:use_store_files] && !RequestStore.store[:journal_files].last.to_a.empty?)

        record
      end

      def get_files(record, args)
        files = []

        RequestStore.store[:journal_files].to_a.pop.to_a.each do |file_data|
          file_data[:created_at_ms] = file_data[:created_at].to_f
          files << Journal::File.new(file_data.merge(id: SecureRandom.uuid, record_id: record.id))
        end if args.delete(:use_store_files)

        if args[:file]
          created_at = Time.zone.now.utc
          files << Journal::File.new(id: SecureRandom.uuid, content: "#{args[:file]}", file_description: "#{args[:file_description]}", content_type: "#{args[:file_type] || 'raw'}", record_id: record.id, request_type: record.request_type, created_at: created_at, created_at_ms: created_at.to_f)
        end

        files
      end

      private

      def filter_parameters(h)
        h.each_with_object({}) do |(k,v),g|
          g[k] = v.is_a?(Hash) ? filter_parameters(v) : (!!k && Rails.application.config.filter_parameters.include?("#{k}".to_sym) ? '*FILTERED*' : v)
        end
      end
    end
  end
end
