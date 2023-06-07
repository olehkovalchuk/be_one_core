require "socket"
module Journal
  module Backend
    class Filebeat
      extend Base

      @@host = `hostname`.strip
      @@revision = `cat #{::File.join('./','REVISION')}`.strip
      @@server_ip = Socket.ip_address_list.detect{ |intf| !intf.ipv4_private? && !intf.ipv4_loopback? }.try(:ip_address)

      def self.save(args)
        record = get_record(args)
        ::File.open(logfile_path, 'a') do |file|
          file.write("#{record.to_json}\n")
        end
        record
      end

      def self.logfile_path
        # "kibana_stat-#{Time.zone.now.utc.strftime('%Y-%m-%d-%H')}.log
        filename = Journal.config.filebeat[:file_prefix].to_s
        filename += Time.zone.now.utc.strftime( Journal.config.filebeat[:append_date_format] ) if Journal.config.filebeat[:append_date_format]
        filename += ".log"
        ::File.join(Journal.config.filebeat[:path], filename)
      end

      def self.configure
        system('mkdir', '-p', Journal.config.filebeat[:path]) unless ::Dir.exist?(Journal.config.filebeat[:path])
      end

      def self.get_record(args)
        args[:id] = SecureRandom.uuid
        args['@timestamp'] ||= Time.zone.now.utc
        args[:created_at_ms] = args['@timestamp'].to_f
        args['@version'] = @@revision
        args['hostname'] = @@host
        args['server_ip'] = @@server_ip
        args
      end
    end
  end
end
