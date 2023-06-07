module BeOneCore
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path("../templates", __FILE__)
    def init
      copy_file "docker-compose.yml", "docker-compose.yml"
      copy_file "env", ".env"
      copy_file "dockerignore", ".dockerignore"
      copy_file "README.md", "README.md"
      copy_file "Dockerfile", "Dockerfile"
      copy_file "docker-entrypoint.sh", "docker-entrypoint.sh"
      copy_file "database.yml", "config/database.yml"
      copy_file "secrets.yml", "config/secrets.yml"


      inject_into_file '.gitignore', after: "/.bundle\n" do <<-'RUBY'
#BeOneCore start
docker-compose.yml
config/secrets.yml
#BeOneCore end
      RUBY
      end
      directory 'docker', 'docker', recursive: true
      # execute_command " "
    end

#     def init_db_if_not_exist
#       run 'rake db:create' unless database_exists?


#       inject_into_file '.gitignore', after: "source 'https://rubygems.org'\n" do <<-'RUBY'
# #BeOneCore start
# gem 'paper_trail'
# #BeOneCore end
#       RUBY
#       end

#       Bundler.with_clean_env do
#         run "bundle install"
#       end

#       run 'rails paper_trail:install'

#     end


    # def database_exists?
    #   ActiveRecord::Base.connection
    # rescue ActiveRecord::NoDatabaseError
    #   false
    # else
    #   true
    # end

  end
end

