#!/usr/bin/env ruby
require 'cluster_common'

if __FILE__ == $0
  input = ARGV[0] #'/tmp/proguard4.3-orig618/numbers.arc'
  num_clusters = ARGV[1].to_i

  g = IGraph::FileRead.read_graph_edgelist(File.new(input), 1)
  g.to_undirected(1)

  merges, modularity = g.community_fastgreedy()

  #save_mod g.community_to_membership(merges, merges.nrow - num_clusters + 1, g.vcount)

  save_merges merges, 'merges_fast'
end
