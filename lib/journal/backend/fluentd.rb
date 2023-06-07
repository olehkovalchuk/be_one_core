module Journal
  module Backend
    class Fluentd
      extend Base

      def self.save(args)
        Fluent::Logger::FluentLogger.open(nil, host: Journal.config.fluentd[:host], port: Journal.config.fluentd[:port])

        record = get_record(args)
        Fluent::Logger.post("log.record-#{Rails.env}", record.to_h)

        get_files(record, args).each do |file|
          Fluent::Logger.post("log.file-#{Rails.env}", file.to_h)
        end

        record
      end
    end
  end
end
