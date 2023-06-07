module BeOneCore
  class Configuration
    attr_accessor :geocoder_key, :geoip_file, :request_types, :http_methods, :http_formats


    def initialize(attrs = {})
      attrs.each_pair do |k,v|
        self.send("#{k}=",v)
      end
    end


  end
end
