module Veri
  module Inputs
    class Tenant < Veri::Inputs::Base
      def resolve
        case tenant = process
        when nil
          { tenant_type: nil, tenant_id: nil }
        when String
          { tenant_type: tenant, tenant_id: nil }
        when Veri::Tenantable
          { tenant_type: tenant.class.to_s, tenant_id: tenant.id }
        end
      end

      private

      def default_error = Veri::InvalidTenantError
      def default_message = "Expected a string, a persisted instance of a model declared with `veri_tenant`, or nil, got `#{@value.inspect}`"

      def validate_and_normalize
        return @value if @value.nil?
        return @value if @value.is_a?(String) && @value.present?
        return @value if @value.is_a?(Veri::Tenantable) && @value.persisted?

        raise_error
      end
    end
  end
end
