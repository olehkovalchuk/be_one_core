module Journal
  module Backtrace
    extend self

    def log_exceptions
      return if (last_exception = $!).nil?

      require 'logger'
      require 'fileutils'

      trace_directory = FileUtils::mkdir_p(Rails.root.join('log', 'backtrace'))
      trace_file = ::File.join(trace_directory, "#{Time.now.strftime('%Y%m%d%H%M%S')}-#{Process.pid}.log")
      trace_log = Logger.new(trace_file)

      # Log the last exception
      trace_log.info "*** Below you'll find the most recent exception thrown, this will likely (but not certainly) be the exception that made your application exit abnormally ***"
      trace_log.error last_exception

      trace_log.info "*** Below you'll find all the exception objects in memory, some of them may have been thrown in your application, others may just be in memory because they are standard exceptions ***"
      ObjectSpace.each_object {|o|
        if ::Exception === o
          trace_log.error o
        end
      }

      trace_log.close
    end
  end
end
