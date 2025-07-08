class AddMultiTenancyToUsers < ActiveRecord::Migration[7.1]
  def up
    # Add references as nullable first
    add_reference :users, :organization, null: true, foreign_key: true
    add_reference :users, :department, null: true, foreign_key: true
    add_reference :users, :team, null: true, foreign_key: true
    add_reference :users, :unit, null: true, foreign_key: true
    add_column :users, :settings, :jsonb, default: {}

    # Create a default organization for existing users
    default_org = Organization.create!(
      name: 'Default Organization',
      slug: 'default-organization',
      status: 'active',
      settings: {
        industry: 'General',
        jurisdiction: 'US',
        compliance_keywords: [],
        exclusion_terms: []
      }
    )

    # Assign existing users to the default organization
    User.update_all(organization_id: default_org.id)

    # Now make organization_id NOT NULL
    change_column_null :users, :organization_id, false
  end

  def down
    remove_reference :users, :organization
    remove_reference :users, :department
    remove_reference :users, :team
    remove_reference :users, :unit
    remove_column :users, :settings
  end
end
