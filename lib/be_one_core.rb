Dir["#{File.dirname(__FILE__)}/core_ext/*.rb"].each { |f| require f }

require "be_one_core/engine"
require "be_one_core/configuration"

require_relative 'uniqueness_validator'
require_relative 'operation/base'
require_relative 'validation/base'
require_relative 'journal'
require_relative 'base_presenter'

module BeOneCore
  class << self
    attr_reader :config

    def configure
      yield config
    end

    def config
      @config || default_config
    end

    def default_config
      Configuration.new(
        geoip_file: File.expand_path('./data/GeoIP.dat',File.dirname(__FILE__)),
        request_types: ["admin","front","default","api"],
        http_methods: ["post","get","put","patch","delete"],
        http_formats: ["html","json","xml","text","js","csv","yaml","rss","atom","ics","all"]
      )
    end


  end
end
