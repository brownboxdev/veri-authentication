require "byebug"
require "veri"
require "database_cleaner/active_record"
require "action_controller/railtie"
require "rspec/rails"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"

  config.expose_dsl_globally = true

  config.include ActiveSupport::Testing::TimeHelpers

  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
  end

  ActiveRecord::Base.establish_connection ENV.fetch("DATABASE_URL", "sqlite3::memory:")

  config.before(:suite) do
    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around do |example|
    Veri::Configuration.reset_to_defaults!

    DatabaseCleaner.cleaning do
      example.run
    end
  end
end

load "#{File.dirname(__FILE__)}/support/schema.rb"

require_relative "support/application"

if [ENV.fetch("ID_TYPE", nil), ActiveRecord::Base.connection.adapter_name] in ["uuid" | "binary_uuid", "Trilogy"]
  [Veri::Session, User, Client, Company].each { |model_class| model_class.before_create { self.id ||= SecureRandom.uuid } }
end

if ENV["ID_TYPE"] == "binary_uuid"
  require_relative "support/binary_uuid_type"

  [Veri::Session, User, Client, Company].each { |model_class| model_class.attribute :id, BinaryUuidType.new }
  [:authenticatable_id, :original_authenticatable_id, :tenant_id, :original_tenant_id].each { |name| Veri::Session.attribute name, BinaryUuidType.new }
end
