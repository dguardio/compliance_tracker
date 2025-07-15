namespace :documents do
  desc "Generate sample documents with faker content for testing"
  task generate_samples: :environment do
    puts "Generating sample documents..."
    
    # Get the first organization or create one
    organization = Organization.first
    if organization.nil?
      puts "No organization found. Creating a sample organization..."
      organization = Organization.create!(
        name: "Sample Organization",
        description: "A sample organization for testing",
        industry: "Technology",
        size: "medium",
        jurisdiction: "US",
        status: "active"
      )
    end
    
    # Create a user if none exists
    user = organization.users.first
    if user.nil?
      puts "No user found. Creating a sample user..."
      user = User.create!(
        email: "admin@sample.com",
        password: "password123",
        password_confirmation: "password123",
        first_name: "Admin",
        last_name: "User",
        organization: organization,
        status: "active"
      )
    end
    
    generator = DocumentGeneratorService.new(organization)
    
    # Generate different types of documents
    document_types = %w[text word excel powerpoint pdf]
    
    document_types.each_with_index do |type, index|
      puts "Generating #{type} document #{index + 1}..."
      document = generator.generate_document(type, index + 1)
      
      if document
        puts "✓ Created: #{document.title}"
      else
        puts "✗ Failed to create #{type} document"
      end
    end
    
    # Generate additional random documents
    puts "Generating additional random documents..."
    5.times do |i|
      type = document_types.sample
      document = generator.generate_document(type, i + 6)
      
      if document
        puts "✓ Created: #{document.title}"
      else
        puts "✗ Failed to create random document"
      end
    end
    
    total_documents = Document.count
    puts "\n✓ Sample document generation complete!"
    puts "Total documents in database: #{total_documents}"
    puts "\nYou can now test the document preview functionality by visiting:"
    puts "http://localhost:3000/documents"
  end

  desc "Clear all sample documents"
  task clear_samples: :environment do
    puts "Clearing all documents..."
    count = Document.count
    Document.destroy_all
    puts "✓ Cleared #{count} documents"
  end

  desc "Generate a specific type of document"
  task :generate, [:type, :count] => :environment do |t, args|
    type = args[:type] || 'text'
    count = (args[:count] || 1).to_i
    
    organization = Organization.first
    if organization.nil?
      puts "No organization found. Please create an organization first."
      exit 1
    end
    
    generator = DocumentGeneratorService.new(organization)
    
    count.times do |i|
      puts "Generating #{type} document #{i + 1}..."
      document = generator.generate_document(type, i + 1)
      
      if document
        puts "✓ Created: #{document.title}"
      else
        puts "✗ Failed to create #{type} document"
      end
    end
    
    puts "\n✓ Document generation complete!"
  end
end 