require "rails/generators/migration"

module Veri
  class AuthenticationGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path("templates", __dir__)

    argument :table_name, type: :string, required: true

    def create_migrations
      primary_key = ActiveRecord::Base.with_connection do |connection|
        raise Thor::Error, "Table `#{table_name}` does not exist, run its migration first" unless connection.table_exists?(table_name)

        connection.columns(table_name).find { |column| column.name == connection.primary_key(table_name) }
      end

      @id_type = primary_key.sql_type
      @sessions_id_type = @id_type unless primary_key.auto_incremented_by_db?
      @sessions_id_default = primary_key.default_function if @sessions_id_type

      migration_template "add_veri_authentication.rb.erb", "db/migrate/add_veri_authentication.rb"
    end

    def self.next_migration_number(_path)
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    end
  end
end
