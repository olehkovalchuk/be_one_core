  config = Rails.application.secrets[:journal]

  Journal.configure do |c|
    c.fluentd = config[:fluentd]
    c.elasticsearch = config[:elasticsearch]
    c.filebeat = config[:filebeat]
    c.enable_backtrace!
  end