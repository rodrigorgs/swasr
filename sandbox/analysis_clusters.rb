#!/usr/bin/env ruby

require 'network'
require 'grok'

edges_file = ARGV[0]
modules_file = ARGV[1]

network = Network.new
network.add_edges(read_pairs(edges_file))
network.set_clusters(read_pairs(modules_file))

#no_cluster = network.nodes.select{ |n| n.cluster.nil? }
#if !no_cluster.empty?
#  root = network.c('ROOT')
#  no_cluster.each { |n| n.cluster = root }
#end
#if network.nodes.any? { |n| n.cluster.nil? } 
#  raise RuntimeError, 'BLI'
#end

#puts "id n e eporn epornn exte intn"

puts "eid size extfraction"

clusters_hash = network.nodes.group_by(&:cluster)
clusters_hash.each_pair do |cluster, nodes|
  edges = nodes.map(&:edges).flatten.uniq
  external_edges = edges.select { |e| e.from.cluster != e.to.cluster }
  #external_in_edges = edges.select { |e| e.to.cluster == cluster }
  #internal_nodes = nodes.select { |n| n.outer_degree == 0 }

  values = []
  values << cluster.eid
  values << nodes.size
  #values << external_in_edges.size / edges.size.to_f
  #values << edges.size / nodes.size.to_f
  #values << edges.size / nodes.size.to_f ** 2
  values << external_edges.size / edges.size.to_f
  #values << internal_nodes.size / nodes.size.to_f

  puts values.join(" ")
end

