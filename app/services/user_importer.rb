require 'csv'

class UserImporter
  attr_reader :errors

  def initialize(file, organization)
    @file = file
    @organization = organization
    @errors = []
  end

  def import
    return false unless valid_file?

    ActiveRecord::Base.transaction do
      CSV.foreach(@file.path, headers: true) do |row|
        process_row(row)
      end
      
      if @errors.any?
        raise ActiveRecord::Rollback
      end
    end

    @errors.empty?
  end

  private

  def valid_file?
    if @file.nil?
      @errors << "No file uploaded"
      return false
    end

    unless @file.content_type == 'text/csv'
      @errors << "File must be a CSV"
      return false
    end

    true
  end

  def process_row(row)
    email = row['email']&.strip
    first_name = row['first_name']&.strip
    last_name = row['last_name']&.strip
    role_name = row['role']&.strip&.downcase

    if email.blank?
      @errors << "Row #{$.}: Email is required"
      return
    end

    user = User.find_or_initialize_by(email: email)
    
    if user.persisted?
      if user.organization_id != @organization.id
        @errors << "Row #{$.}: User #{email} already belongs to another organization"
        return
      end
      # Update existing user if needed, or just skip
    else
      user.first_name = first_name
      user.last_name = last_name
      user.organization = @organization
      user.password = Devise.friendly_token[0, 20] # Generate random password
      
      unless user.save
        @errors << "Row #{$.}: #{user.errors.full_messages.join(', ')}"
        return
      end

      # Send invitation (if using Devise Invitable, we would use User.invite!)
      # For now, we assume standard creation and maybe send a manual email later
      # Or better, use Devise Invitable if available. 
      # Checking User model... standard Devise seems to be used.
    end

    # Assign Role
    if role_name.present?
      role = @organization.roles.find_by(name: role_name)
      if role
        user.add_role(role.name.to_sym, @organization)
      else
        @errors << "Row #{$.}: Role '#{role_name}' not found"
      end
    end
  end
end
