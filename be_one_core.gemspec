$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "be_one_core/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "be_one_core"
  spec.version     = BeOneCore::VERSION
  spec.authors     = ["Aleksander Chernov"]
  spec.email       = ["boss@beone.software"]
  spec.homepage    = "https://gems.beone.software/"
  spec.summary     = "BeOneCore"
  spec.description = "Common functionality"
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://gems.beone.software/"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.0.0.rc1"
  spec.add_dependency 'virtus'
  spec.add_dependency 'signinable'
  spec.add_dependency 'email_validator'
  spec.add_dependency 'file_validators'
  spec.add_dependency 'date_validator'
  spec.add_dependency 'validate_url'
  spec.add_dependency 'multilang-hstore', '~> 1.0.0'
  spec.add_dependency 'positionable'
  spec.add_dependency 'request_store'
  spec.add_dependency 'pg'
  spec.add_dependency 'geocoder'
  spec.add_dependency 'geoip'
  spec.add_dependency 'bcrypt'
  spec.add_dependency 'paper_trail'
  spec.add_dependency 'image_processing'
  spec.add_dependency "spreadsheet"



  spec.add_dependency 'elasticsearch-persistence', '7.0.0'
  spec.add_dependency 'fluent-logger', '0.8.2'


  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'arel-pg-json'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency "sqlite3"
end
