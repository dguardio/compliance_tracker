class Users::RegistrationsController < Devise::RegistrationsController
  # Devise RegistrationsController automatically skips standard authentication for new/create,
  # but we still need to skip our custom tenant scoping so users can create accounts without an organization
  skip_before_action :set_current_tenant, only: [:new, :create]

  def create
    build_resource(sign_up_params)

    # Process settings
    settings = {}
    settings[:first_name] = params[:user][:first_name] if params[:user][:first_name].present?
    settings[:last_name] = params[:user][:last_name] if params[:user][:last_name].present?
    settings[:job_title] = params[:user][:job_title] if params[:user][:job_title].present?
    settings[:phone] = params[:user][:phone] if params[:user][:phone].present?
    settings[:timezone] = params[:user][:timezone] if params[:user][:timezone].present?
    settings[:compliance_preferences] = {}
    settings[:notification_settings] = {}
    settings[:ui_preferences] = {}
    settings[:custom_fields] = {}

    resource.settings = settings

    # Auto-build Organization for Self-Serve flow
    org_name = params[:user][:organization_name]
    if org_name.present?
      resource.build_organization(name: org_name, status: 'active')
    end

    resource.save
    yield resource if block_given?
    
    if resource.persisted?
      # Set default roles
      resource.add_role(:user)
      if org_name.present?
        # Make them the Admin of their newly created organization
        resource.add_role('Admin', resource.organization)
        resource.add_role(:org_admin, resource.organization)
      end

      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource, status: :unprocessable_entity
    end
  end

  protected

  def sign_up_params
    params.require(:user).permit(
      :email, :password, :password_confirmation,
      :organization_id, :department_id, :team_id, :unit_id,
      :first_name, :last_name, :job_title, :phone, :timezone,
      :organization_name
    )
  end
end
