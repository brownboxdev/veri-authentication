module Veri
  module Tenantable; end

  module TenantDeclaration
    def veri_tenant
      include Veri::Tenantable

      before_destroy { Veri::Session.in_tenant(self).or(Veri::Session.in_original_tenant(self)).terminate_all }
    end
  end
end
