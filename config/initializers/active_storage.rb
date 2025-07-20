# Configure Active Storage URL options
Rails.application.config.after_initialize do
  # Set default URL options for Active Storage
  if Rails.env.development?
    Rails.application.routes.default_url_options = { host: 'localhost', port: 3000 }
  elsif Rails.env.production?
    # In production, you should set this via environment variable
    host = ENV['APPLICATION_HOST'] || 'localhost'
    protocol = ENV['APPLICATION_PROTOCOL'] || 'https'
    Rails.application.routes.default_url_options = { host: host, protocol: protocol }
  end
end
