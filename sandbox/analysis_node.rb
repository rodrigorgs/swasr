#!/usr/bin/env ruby

require 'grok'
require 'network'

if ARGV.size < 2
  puts "Parameters: l1.pairs modules.pairs"
  exit 1
end

g = Network.new
STDERR.puts "Reading pairs..."
pairs = read_pairs(ARGV[0])
STDERR.puts "Creating edges..."
g.add_edges(pairs)
STDERR.puts "Reading modules..."
clusters = read_pairs(ARGV[1])
STDERR.puts "Creating clusters..."
g.set_clusters(clusters)

puts "deg indeg outdeg nclusters o_indeg i_indeg o_outdeg i_outdeg"
g.nodes.each do |n|
  STDERR.puts n.id
  puts "#{n.degree} #{n.in_degree} #{n.out_degree} #{n.cluster_span}" +
      " #{n.outer_in_degree} #{n.inner_in_degree} #{n.outer_out_degree} " +
      " #{n.inner_out_degree}"
end

