class AllowNullOrganizationIdInPermissions < ActiveRecord::Migration[7.1]
  def change
    # Allow organization_id to be NULL for global permissions (super admin permissions)
    # Organization-specific permissions should still have organization_id set
    change_column_null :permissions, :organization_id, true
  end
end
