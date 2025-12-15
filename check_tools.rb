begin
  require 'ruby_llm'
  puts "Checking for RubyLLM::Tools::GoogleSearch..."
  puts RubyLLM::Tools::GoogleSearch.name
rescue NameError
  puts "RubyLLM::Tools::GoogleSearch NOT FOUND"
end

begin
  require 'ruby_llm'
  puts "Checking for RubyLLM::Tools::WebBrowser..."
  puts RubyLLM::Tools::WebBrowser.name
rescue NameError
  puts "RubyLLM::Tools::WebBrowser NOT FOUND"
end
