class Role < ApplicationRecord
  has_and_belongs_to_many :users, :join_table => :users_roles
  
  belongs_to :resource,
             :polymorphic => true,
             :optional => true
  
  # Configure Rolify resource types
  rolify
  
  # Validations
  validates :name, presence: true, uniqueness: { scope: [:resource_type, :resource_id] }
  validates :resource_type,
            :inclusion => { :in => %w[Organization Department Team Unit User] },
            :allow_nil => true

  # Scopes
  scope :global_roles, -> { where(resource: nil) }
  scope :organization_roles, -> { where(resource_type: 'Organization') }
  scope :department_roles, -> { where(resource_type: 'Department') }
  scope :team_roles, -> { where(resource_type: 'Team') }
  scope :unit_roles, -> { where(resource_type: 'Unit') }
  scope :by_name, -> { order(:name) }
  
  # Instance methods
  def display_name
    if resource
      "#{name.titleize} (#{resource.display_name})"
    else
      name.titleize
    end
  end
  
  def global?
    resource.nil?
  end
  
  def organization_role?
    resource_type == 'Organization'
  end
  
  def department_role?
    resource_type == 'Department'
  end
  
  def team_role?
    resource_type == 'Team'
  end
  
  def unit_role?
    resource_type == 'Unit'
  end
  
  def user_count
    users.count
  end
  
  def description
    case name
    when 'super_admin'
      'Full system access across all organizations'
    when 'admin'
      'Administrative access within organization'
    when 'organization_admin'
      'Administrative access for specific organization'
    when 'department_admin'
      'Administrative access for specific department'
    when 'team_lead'
      'Leadership role for specific team'
    when 'unit_manager'
      'Management role for specific unit'
    when 'compliance_officer'
      'Compliance management and oversight'
    when 'user'
      'Standard user access'
    else
      'Custom role'
    end
  end

  scopify
end
