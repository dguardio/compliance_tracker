# Debug SourceDiscoveryAgent
require_relative 'config/environment'

puts "Running SourceDiscoveryAgent..."
agent = SourceDiscoveryAgent.new
results = agent.call(sector: "Healthcare", jurisdiction: "USA")

puts "Results: #{results.inspect}"
