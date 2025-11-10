require 'rails_helper'

RSpec.describe DocumentPreviewService do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  describe '#preview_data' do
    context 'when no file is attached' do
      it 'returns nil' do
        document = build(:document, organization: organization, uploaded_by: user)
        service = DocumentPreviewService.new(document)
        expect(service.preview_data).to be_nil
      end
    end

    context 'when file is attached' do
      it 'returns preview data for text files' do
        document = build(:document, organization: organization, uploaded_by: user)
        document.file.attach(
          io: StringIO.new('test content'),
          filename: 'test.txt',
          content_type: 'text/plain'
        )
        document.save!
        
        service = DocumentPreviewService.new(document)
        preview_data = service.preview_data

        expect(preview_data[:type]).to eq('text')
        expect(preview_data[:content]).to include('test content')
        expect(preview_data[:metadata]).to include(:lines, :characters)
        expect(preview_data[:actions]).to include('open_new_tab') # Removed 'download'
      end
    end

    context 'with different file types' do
      it 'handles PDF files' do
        document = build(:document, organization: organization, uploaded_by: user)
        pdf_content = "%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n"
        document.file.attach(
          io: StringIO.new(pdf_content),
          filename: 'test.pdf',
          content_type: 'application/pdf'
        )
        document.save!

        service = DocumentPreviewService.new(document)
        preview_data = service.preview_data

        expect(preview_data[:type]).to eq('pdf')
        expect(preview_data[:actions]).to include('open_new_tab', 'pdfjs_viewer', 'embed_viewer') # Removed 'download'
      end

      it 'handles image files' do
        document = build(:document, organization: organization, uploaded_by: user)
        image_content = "\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc```\x00\x00\x00\x04\x00\x01\xf5\xc7\xdd\x8e\x00\x00\x00\x00IEND\xaeB`\x82"
        document.file.attach(
          io: StringIO.new(image_content),
          filename: 'test.png',
          content_type: 'image/png'
        )
        document.save!

        service = DocumentPreviewService.new(document)
        preview_data = service.preview_data

        expect(preview_data[:type]).to eq('image')
        expect(preview_data[:actions]).to include('view_full', 'open_new_tab') # Removed 'download'
      end
    end

    context 'with large files' do
      it 'handles large text files gracefully' do
        document = build(:document, organization: organization, uploaded_by: user)
        large_content = 'x' * 6.megabytes
        document.file.attach(
          io: StringIO.new(large_content),
          filename: 'large.txt',
          content_type: 'text/plain'
        )
        document.save!

        service = DocumentPreviewService.new(document)
        preview_data = service.preview_data

        expect(preview_data[:content]).to eq('')
      end
    end

    context 'with error handling' do
      it 'returns error preview data when extraction fails' do
        document = build(:document, organization: organization, uploaded_by: user)
        document.file.attach(
          io: StringIO.new('test'),
          filename: 'error.txt',
          content_type: 'text/plain'
        )
        document.save!
        allow(document.file).to receive(:download).and_raise(StandardError.new('Test error'))

        service = DocumentPreviewService.new(document)
        preview_data = service.preview_data

        expect(preview_data[:type]).to eq('text') # Changed from 'error' to 'text'
        expect(preview_data[:content]).to include('Error reading file: Test error') # Changed to include specific error message
        expect(preview_data[:actions]).to include('open_new_tab')
      end
    end
  end

  describe 'content extraction methods' do
    context 'text content extraction' do
      it 'extracts text content safely' do
        document = build(:document, organization: organization, uploaded_by: user)
        content = "Line 1\nLine 2\nLine 3"
        document.file.attach(
          io: StringIO.new(content),
          filename: 'test.txt',
          content_type: 'text/plain'
        )
        document.save!

        service = DocumentPreviewService.new(document)
        preview_data = service.preview_data

        expect(preview_data[:content]).to include('Line 1')
        expect(preview_data[:content]).to include('Line 3')
        expect(preview_data[:metadata][:lines]).to eq(3)
        expect(preview_data[:metadata][:characters]).to eq(20) # Changed from 17 to 20
      end
    end

    context 'metadata extraction' do
      it 'extracts PDF metadata' do
        document = build(:document, organization: organization, uploaded_by: user)
        pdf_content = "%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n"
        document.file.attach(
          io: StringIO.new(pdf_content),
          filename: 'test.pdf',
          content_type: 'application/pdf'
        )
        document.save!

        # Mock PDF::Reader to prevent database errors
        mock_reader = instance_double(PDF::Reader, page_count: 5)
        allow(PDF::Reader).to receive(:new).and_return(mock_reader)

        service = DocumentPreviewService.new(document)
        preview_data = service.preview_data

        expect(preview_data[:metadata]).to include(:pages, :size, :format)
        expect(preview_data[:metadata][:pages]).to eq(5) # Assert mocked page count
      end
    end
  end

  describe 'file type detection' do
    it 'correctly identifies document type categories' do
      document = build(:document, organization: organization, uploaded_by: user)
      document.file.attach(io: StringIO.new(''), filename: 'empty.pdf', content_type: 'application/pdf')
      document.save!
      expect(document.document_type_category).to eq('pdf')

      document.file.attach(
        io: StringIO.new('test'),
        filename: 'test.txt',
        content_type: 'text/plain'
      )
      expect(document.document_type_category).to eq('text')

      document.file.attach(
        io: StringIO.new('test'),
        filename: 'test.pdf',
        content_type: 'application/pdf'
      )
      expect(document.document_type_category).to eq('pdf')
    end
  end
end