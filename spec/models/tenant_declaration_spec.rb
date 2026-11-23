RSpec.describe Veri::TenantDeclaration do
  let(:company) { Company.create! }
  let(:other_company) { Company.create! }

  def create_session(**attributes)
    Veri::Session.create!(
      expires_at: 1.hour.from_now,
      authenticatable: User.create!,
      hashed_token: SecureRandom.hex,
      last_seen_at: Time.current,
      **attributes
    )
  end

  describe "destroying a tenant" do
    subject { company.destroy! }

    let!(:session_in_tenant) { create_session(tenant: company) }
    let!(:session_returning_to_tenant) do
      create_session(tenant: other_company, original_tenant: company, original_authenticatable: User.create!)
    end
    let!(:session_in_other_tenant) { create_session(tenant: other_company) }
    let!(:session_in_string_tenant) { create_session(tenant_type: "subdomain") }
    let!(:session_without_tenant) { create_session }

    it "deletes the sessions in the tenant" do
      expect { subject }.to change { Veri::Session.exists?(session_in_tenant.id) }.from(true).to(false)
    end

    it "deletes the impersonating sessions that return to the tenant" do
      expect { subject }.to change { Veri::Session.exists?(session_returning_to_tenant.id) }.from(true).to(false)
    end

    it "keeps the other sessions" do
      subject
      expect(Veri::Session.all).to contain_exactly(session_in_other_tenant, session_in_string_tenant, session_without_tenant)
    end

    context "when the destroy is rolled back" do
      subject do
        Company.transaction do
          company.destroy!
          raise ActiveRecord::Rollback
        end
      end

      it "keeps the sessions" do
        expect { subject }.not_to change(Veri::Session, :count)
      end
    end
  end
end
