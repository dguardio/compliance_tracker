class RegulationDiffService
  def initialize(regulation, previous_regulation)
    @regulation = regulation
    @previous_regulation = previous_regulation
  end

  def call
    return @regulation.full_text['extracted_content'] unless @previous_regulation

    current_text = @regulation.full_text['extracted_content'] || ''
    previous_text = @previous_regulation.full_text['extracted_content'] || ''

    # Use Diffy to generate HTML diff
    # context: :all ensures the full text is returned with inline changes
    diff = Diffy::Diff.new(previous_text, current_text, context: 10000).to_s(:html)
    
    # Diffy wraps content in <div class="diff">...</div>
    # We can customize the CSS in the PDF view
    diff
  end
end
