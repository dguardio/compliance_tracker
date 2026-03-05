require_relative 'config/environment'

regs = Regulation.last(3)
if regs.any?
  regs.each do |reg|
    puts "--- Regulation #{reg.id} ---"
    puts "Title: #{reg.title}"
    puts "Data Source: #{reg.external_id}"
    puts "Status: #{reg.status}"
    puts "Full text length: #{reg.full_text['extracted_content']&.length || 0}"
  end
else
  puts "No regulations found."
end

puts "--- Errors if any ---"
Delayed::Job.all.each do |job|
  puts job.last_error if job.last_error.present?
end if defined?(Delayed::Job)

