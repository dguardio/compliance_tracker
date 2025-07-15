require 'rails_helper'

RSpec.describe DocumentPreviewService do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:document) { create(:document, organization: organization, uploaded_by: user) }

  describe '#preview_data' do
    context 'when no file is attached' do
      it 'returns nil' do
        service = DocumentPreviewService.new(document)
        expect(service.preview_data).to be_nil
      end
    end

    context 'when file is attached' do
      before do
        document.file.attach(
          io: StringIO.new('test content'),
          filename: 'test.txt',
          content_type: 'text/plain'
        )
      end

      it 'returns preview data for text files' do
        service = DocumentPreviewService.new(document)
        preview_data = service.preview_data

        expect(preview_data[:type]).to eq('text')
        expect(preview_data[:content]).to include('test content')
        expect(preview_data[:metadata]).to include(:lines, :characters)
        expect(preview_data[:actions]).to include('download')
      end
    end

    context 'with different file types' do
      it 'handles PDF files' do
        # Create a simple PDF file for testing
        pdf_content = "%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n"
        document.file.attach(
          io: StringIO.new(pdf_content),
          filename: 'test.pdf',
          content_type: 'application/pdf'
        )

        service = DocumentPreviewService.new(document)
        preview_data = service.preview_data

        expect(preview_data[:type]).to eq('pdf')
        expect(preview_data[:actions]).to include('download', 'open_new_tab')
      end

      it 'handles image files' do
        # Create a simple image file for testing
        image_content = "\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc```\x00\x00\x00\x04\x00\x01\xf5\xc7\xdd\x8e\x00\x00\x00\x00IEND\xaeB`\x82"
        document.file.attach(
          io: StringIO.new(image_content),
          filename: 'test.png',
          content_type: 'image/png'
        )

        service = DocumentPreviewService.new(document)
        preview_data = service.preview_data

        expect(preview_data[:type]).to eq('image')
        expect(preview_data[:actions]).to include('download', 'view_full')
      end
    end

    context 'with large files' do
      it 'handles large text files gracefully' do
        large_content = 'x' * 6.megabytes
        document.file.attach(
          io: StringIO.new(large_content),
          filename: 'large.txt',
          content_type: 'text/plain'
        )

        service = DocumentPreviewService.new(document)
        preview_data = service.preview_data

        expect(preview_data[:content]).to eq('')
      end
    end

    context 'with error handling' do
      it 'returns error preview data when extraction fails' do
        # Mock a file that will cause an error
        allow(document.file).to receive(:attached?).and_return(true)
        allow(document.file).to receive(:content_type).and_return('application/pdf')
        allow(document.file).to receive(:download).and_raise(StandardError.new('Test error'))

        service = DocumentPreviewService.new(document)
        preview_data = service.preview_data

        expect(preview_data[:type]).to eq('error')
        expect(preview_data[:content]).to include('Test error')
        expect(preview_data[:actions]).to include('download')
      end
    end
  end

  describe 'content extraction methods' do
    context 'text content extraction' do
      it 'extracts text content safely' do
        content = "Line 1\nLine 2\nLine 3"
        document.file.attach(
          io: StringIO.new(content),
          filename: 'test.txt',
          content_type: 'text/plain'
        )

        service = DocumentPreviewService.new(document)
        preview_data = service.preview_data

        expect(preview_data[:content]).to include('Line 1')
        expect(preview_data[:content]).to include('Line 3')
        expect(preview_data[:metadata][:lines]).to eq(3)
        expect(preview_data[:metadata][:characters]).to eq(17)
      end
    end

    context 'metadata extraction' do
      it 'extracts PDF metadata' do
        pdf_content = "%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n"
        document.file.attach(
          io: StringIO.new(pdf_content),
          filename: 'test.pdf',
          content_type: 'application/pdf'
        )

        service = DocumentPreviewService.new(document)
        preview_data = service.preview_data

        expect(preview_data[:metadata]).to include(:pages, :size, :format)
      end
    end
  end

  describe 'file type detection' do
    it 'correctly identifies document type categories' do
      expect(document.document_type_category).to eq('unknown')

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