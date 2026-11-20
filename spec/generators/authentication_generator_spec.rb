require "rails/generators"
require "generators/veri/authentication_generator"

RSpec.describe Veri::AuthenticationGenerator do
  subject { described_class.start(args) }

  let(:args) { [:my_users] }
  let(:migration_file) { "db/migrate/20221201201056_add_veri_authentication.rb" }
  let(:id_column) { ActiveRecord::Base.connection.columns(:my_users).find { |column| column.name == "id" } }
  let(:id_type) { id_column.sql_type }
  let(:migration_content) do
    <<~MIGRATION
      class AddVeriAuthentication < ActiveRecord::Migration[6.2]
        def change
          add_column :my_users, :hashed_password, :text
          add_column :my_users, :password_updated_at, :datetime
          add_column :my_users, :suspended, :boolean, default: false, null: false
          add_column :my_users, :suspended_at, :datetime

          create_table :veri_sessions#{sessions_table_options} do |t|
            t.string :hashed_token, null: false, index: { unique: true }
            t.datetime :expires_at, null: false
            t.belongs_to :authenticatable, null: false, foreign_key: { to_table: :my_users, primary_key: primary_key(:my_users) }, index: true, type: #{id_type.inspect}
            t.belongs_to :original_authenticatable, foreign_key: { to_table: :my_users, primary_key: primary_key(:my_users) }, index: true, type: #{id_type.inspect}
            t.belongs_to :tenant, polymorphic: true, index: true, type: #{id_type.inspect}
            t.belongs_to :original_tenant, polymorphic: true, index: true, type: #{id_type.inspect}
            t.datetime :shapeshifted_at
            t.datetime :last_seen_at, null: false
            t.string :ip_address
            t.text :user_agent

            t.timestamps
          end
        end
      end
    MIGRATION
  end

  before do
    allow(Time).to receive(:now).and_return(Time.new(2022, 12, 1, 21, 10, 56, "+01:00"))
    allow(ActiveRecord::Migration).to receive(:current_version).and_return(6.2)
  end

  after do
    ActiveRecord::Base.connection.drop_table(:my_users, if_exists: true)
    FileUtils.rm_rf(Dir.glob("db"))
  end

  shared_examples "a migration generator" do
    before { subject }

    it "generates a properly named migration file" do
      expect(File).to exist(migration_file)
    end

    it "generates a migration file with proper content" do
      expect(File.read(migration_file)).to eq(migration_content)
    end
  end

  context "when the users table has auto-incrementing ids" do
    let(:sessions_table_options) { "" }

    before { ActiveRecord::Base.connection.create_table(:my_users, force: true) }

    it_behaves_like "a migration generator"
  end

  context "when the users table has ids set by the app" do
    let(:sessions_table_options) { ", id: #{id_type.inspect}" }

    before do
      ActiveRecord::Base.connection.create_table(:my_users, id: false, force: true) do |t|
        t.string :id, primary_key: true, limit: 36
      end
    end

    it_behaves_like "a migration generator"
  end

  context "when the users table has ids set by the database" do
    let(:sessions_table_options) { ", id: #{id_type.inspect}, default: -> { #{id_column.default_function.inspect} }" }

    before do
      ActiveRecord::Base.connection.create_table(:my_users, id: false, force: true) do |t|
        t.string :id, primary_key: true, limit: 36, default: -> { "(lower('ABC'))" }
      end
    end

    it_behaves_like "a migration generator"
  end

  context "when the table does not exist" do
    let(:args) { [:missing_users] }

    it "stops with an error" do
      expect { subject }.to output("Table `missing_users` does not exist, run its migration first\n").to_stderr
    end

    it "does not generate a migration" do
      expect { subject }.to output.to_stderr
      expect(Dir.glob("db/migrate/*")).to be_empty
    end
  end
end
