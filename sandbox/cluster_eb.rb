#!/usr/bin/env ruby
require 'cluster_common'

if __FILE__ == $0

  input = ARGV[0] #'/tmp/proguard4.3-orig618/numbers.arc'
  num_clusters = ARGV[1].to_i

  g = IGraph::FileRead.read_graph_edgelist(File.new(input), 1)

  merges, _, _, _ = g.community_edge_betweenness(true)

  #better_group = []
  #better_modularity = -1
  #
  #merges.nrow.times do |steps|
  #  group = g.community_to_membership(merges, steps, g.vcount)
  #  modularity = g.modularity(group)
  #  #puts modularity
  #
  #  if (modularity > better_modularity)
  #    better_modularity = modularity
  #    better_group = group
  #  end
  #end

  #p better_group

  #save_mod g.community_to_membership(merges, merges.nrow - num_clusters + 1, g.vcount)

  save_merges merges, 'merges_eb'
end
