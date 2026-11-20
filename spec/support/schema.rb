require "rails/generators"
require "generators/veri/authentication_generator"
require "tmpdir"

ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define do
  drop_table :veri_sessions, if_exists: true

  [:users, :clients, :companies].each do |table|
    case [ENV.fetch("ID_TYPE", nil), connection.adapter_name]
    in ["uuid", "PostgreSQL"] then create_table table, id: :uuid, force: true, &:timestamps
    in ["uuid", "Trilogy"] then create_table table, id: :string, limit: 36, force: true, &:timestamps
    in ["binary_uuid", "Trilogy"] then create_table table, id: :binary, limit: 16, force: true, &:timestamps
    else create_table table, force: true, &:timestamps
    end
  end
end

Dir.mktmpdir do |dir|
  Veri::AuthenticationGenerator.start(["users", "--quiet"], destination_root: dir)
  load Dir["#{dir}/db/migrate/*.rb"].first
end

AddVeriAuthentication.migrate(:up)
