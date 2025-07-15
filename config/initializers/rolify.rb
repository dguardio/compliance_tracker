Rolify.configure do |config|
  # By default ORM adapter is ActiveRecord. uncomment to use mongoid
  # config.use_mongoid

  # Dynamic shortcuts for User class (user.is_admin? like methods). Default is: false
  config.use_dynamic_shortcuts
  if ActiveRecord::Base.connection.table_exists? 'roles'
    config.use_dynamic_shortcuts
  end
  # Configuration to remove roles from database once the last resource is removed. Default is: true
  # config.remove_role_if_empty = false
end
