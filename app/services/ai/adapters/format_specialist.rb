require 'open-uri'

module Ai
  module Adapters
    class FormatSpecialist
      def extract(url)
        # Download tmp file
        temp_file = download_to_temp(url)
        return nil unless temp_file

        extension = File.extname(temp_file.path).downcase
        
        text = case extension
               when '.pdf'
                 extract_pdf(temp_file)
               when '.docx'
                 extract_docx(temp_file)
               when '.xml'
                 extract_xml(temp_file)
               else
                 Rails.logger.warn "FormatSpecialist: Unsupported extension #{extension}"
                 nil
               end

        return nil if text.blank?

        {
          full_text: text,
          content_type: MIME::Types.type_for(extension).first.content_type
        }
      ensure
        temp_file&.close
        temp_file&.unlink
      end

      private

      def download_to_temp(url)
        # Secure download
        down = URI.open(url)
        temp = Tempfile.new(['download', File.extname(url)])
        IO.copy_stream(down, temp)
        temp.rewind
        temp
      rescue => e
        Rails.logger.error "FormatSpecialist download failed: #{e.message}"
        nil
      end

      def extract_pdf(file)
        PDF::Reader.new(file).pages.map(&:text).join("\n")
      rescue => e
        Rails.logger.error "PDF extraction failed: #{e.message}"
        nil
      end

      def extract_docx(file)
        Docx::Document.open(file.path).text
      rescue => e
        Rails.logger.error "DOCX extraction failed: #{e.message}"
        nil
      end

      def extract_xml(file)
        doc = Nokogiri::XML(File.read(file.path))
        doc.remove_namespaces!
        doc.text # Naive text extraction
      end
    end
  end
end
