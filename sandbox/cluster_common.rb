require 'igraph'
require 'grok'

def save_merges(merges, filename)
  puts_pairs(merges.to_a, filename)
end

def save_mod(clusters)
  clusters.each_with_index do |cluster, i|
    cluster.each { |v| puts "#{v} #{i}" }
  end
end
