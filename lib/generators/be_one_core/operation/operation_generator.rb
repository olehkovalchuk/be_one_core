module BeOneCore
  class OperationGenerator < Rails::Generators::Base
    source_root File.expand_path("../templates", __FILE__)
    include Rails::Generators::Migration
    argument :model, type: :string
    argument :namespace, type: :string, default: nil
    def init
      template "operation.rb.erb", file_name('operation').downcase
      template "validation.rb.erb", file_name('validation').downcase
      template "action.rb.erb", file_name('action').downcase
      template "model.rb.erb", file_name('model', true).downcase
    end

    def copy_migration_tables
       migration_template "create_model_migration.rb.erb", "db/migrate/create_#{[namespace,model].reject(&:blank?).join('_')}.rb"
    end


    def self.next_migration_number(path)
      unless @prev_migration_nr
        @prev_migration_nr = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
      else
        @prev_migration_nr += 1
      end
      @prev_migration_nr.to_s
    end

    private 
    def file_name( type, is_model = false )
      path = ['app',type.pluralize]
      path << namespace if namespace
      path << (is_model ? "#{model.singularize.downcase}.rb" : "#{model.singularize.downcase}_#{type}.rb")
      path.join("/")
    end
  end
end
