require 'request_store'
require 'email_validator'
require 'file_validators'
require 'date_validator'
require 'validate_url'
require 'virtus'
require 'signinable'
require 'positionable'
require 'paper_trail'

require 'multilang-hstore'

#GEO
require 'geocoder'
require 'geoip'
#LOGGER
require 'elasticsearch/persistence'
require 'digest/md5'
require 'fluent-logger'

require_relative 'railtie'
require_relative 'geo'
require_relative 'password'

module BeOneCore
  class Engine < ::Rails::Engine
    isolate_namespace BeOneCore
    initializer 'add_config_files', after: :load_config_initializers do |app|
      app.config.paths["config"] << root.join('config')
    end

    initializer "be_one_core.add_operation_process_method" do |app|
      ActionController::Base.send :include, BeOneCore::Controller
    end

  end
end
