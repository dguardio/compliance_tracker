class RegulationDiffService
  def initialize(organization)
    @organization = organization
  end

  # Compare two versions of a regulation text and return structured diff
  def diff(regulation, old_text: nil, new_text: nil)
    old_text ||= regulation.previous_version_text || ''
    new_text ||= regulation.body || regulation.description || ''

    return { sections: [], summary: 'No content to compare' } if old_text.blank? && new_text.blank?

    old_sections = parse_sections(old_text)
    new_sections = parse_sections(new_text)

    # Find added, removed, and modified sections
    all_keys = (old_sections.keys + new_sections.keys).uniq
    
    diff_sections = all_keys.map do |key|
      old_content = old_sections[key]
      new_content = new_sections[key]

      if old_content.nil?
        { title: key, change_type: 'added', new_content: new_content, old_content: nil }
      elsif new_content.nil?
        { title: key, change_type: 'removed', new_content: nil, old_content: old_content }
      elsif old_content != new_content
        { title: key, change_type: 'modified', new_content: new_content, old_content: old_content }
      else
        nil # unchanged
      end
    end.compact

    summary = generate_diff_summary(diff_sections)

    {
      sections: diff_sections,
      summary: summary,
      added_count: diff_sections.count { |s| s[:change_type] == 'added' },
      removed_count: diff_sections.count { |s| s[:change_type] == 'removed' },
      modified_count: diff_sections.count { |s| s[:change_type] == 'modified' },
      total_changes: diff_sections.size
    }
  end

  private

  def parse_sections(text)
    sections = {}
    current_title = 'Introduction'
    current_content = []

    text.split("\n").each do |line|
      if line.match?(/^(Article|Section|Part)\s+/i) || line.match?(/^\d+\.\s+[A-Z]/)
        sections[current_title] = current_content.join("\n").strip if current_content.any?
        current_title = line.strip
        current_content = []
      else
        current_content << line
      end
    end
    sections[current_title] = current_content.join("\n").strip if current_content.any?
    sections
  end

  def generate_diff_summary(sections)
    return 'No changes detected.' if sections.empty?

    parts = []
    added = sections.count { |s| s[:change_type] == 'added' }
    removed = sections.count { |s| s[:change_type] == 'removed' }
    modified = sections.count { |s| s[:change_type] == 'modified' }

    parts << "#{added} new section(s) added" if added > 0
    parts << "#{removed} section(s) removed" if removed > 0
    parts << "#{modified} section(s) modified" if modified > 0

    parts.join(', ') + '.'
  end
end
