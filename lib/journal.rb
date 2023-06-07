require 'journal/configuration'
require 'journal/repository'
require 'journal/error'
require 'journal/parametrizer/default'
require 'journal/backend/base'
require 'journal/backend/elasticsearch'
require 'journal/backend/fluentd'
require 'journal/backend/filebeat'

# Storing journal records and files in ElasticSearch
module Journal
  STATUS = {
    success: 1,
    failure: 2,
    exception: 3,
    unknown: 4
  }.freeze

  extend self

  STATUS.keys.each do |key|
    self.class.send(:define_method, key) do |args|
      args = args.merge(status: STATUS[key])
      # args = args.merge(execution_time: @start) unless args.incude?(:execution_time)
      push(args)
    end
   end

  def configure
    yield(config)
  end

  def config
    return @config if @config
    @config = Configuration.new
    @config.configure_backends
    @config
  end

  # Wrapper for safe execution of any code
  def safe_action(args={}, &block)
    RequestStore.store[:journal_files] ||= []
    RequestStore.store[:journal_files].push([])
    @start = Time.zone.now
    result = yield

    status = RequestStore.store[:journal_log_success] == false ? :failure : :success
    push(args.merge(status: STATUS[status], created_at: @start.utc, execution_time: (Time.zone.now.to_f - @start.to_f), use_store_files: true))
    result
  rescue Journal::Error => je
    failure(args.merge(created_at: @start.utc, execution_time: (Time.zone.now.to_f - @start.to_f), use_store_files: true, description: "#{je.code} - #{je.message}"))
  rescue Exception => e
    exception(args.merge(description: e.message, file: e.backtrace.join("\n"), file_description: :backtrace, created_at: @start.utc, execution_time: (Time.zone.now.to_f - @start.to_f), use_store_files: true))
    fail e
  end

  def add_file(content, description, content_type='raw')
    RequestStore.store[:journal_files].last << {
      content: "#{content}",
      file_description: "#{description}",
      content_type: "#{content_type}",
      created_at: Time.zone.now.utc
    } if RequestStore.store[:journal_files].is_a?(Array)
  end

  def push(args)
    limit ||= 3
    Record.push(args)
  rescue Exception => e
    limit -= 1
    if limit.zero?
      Rails.logger.error '***** LOG PUSH ERROR START *****'
      Rails.logger.error e.message
      Rails.logger.error '-' * 30
      Rails.logger.error e.backtrace.join("\n")
      Rails.logger.error '***** LOG PUSH ERROR END *****'
    else
      retry
    end
  end
end
