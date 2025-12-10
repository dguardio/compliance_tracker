# config/initializers/active_record_encryption.rb

# In development/test, if credentials aren't set, provide default keys for encryption to work.
if Rails.env.development? || Rails.env.test?
  ActiveRecord::Encryption.configure(
    primary_key: ENV.fetch('ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY', 'test_primary_key_must_be_at_least_32_bytes_long_123'),
    deterministic_key: ENV.fetch('ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY', 'test_deterministic_key_must_be_at_least_32_bytes_long_123'),
    key_derivation_salt: ENV.fetch('ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT', 'test_salt_must_be_at_least_32_bytes_long_123')
  )
  puts "ActiveRecord Encryption keys configured for development/test."
end
