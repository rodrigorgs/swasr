#!/usr/bin/env ruby
require 'igraph'
require 'grok'
require 'cluster_common'

f_merges = ARGV[0]
steps = ARGV[1].to_i
n = ARGV[2].to_i
#f_out = ARGV[3]

merges = read_pairs(f_merges).map { |x| [x[0].to_f, x[1].to_f] }
merges = IGraphMatrix.new(*merges)

g = IGraph::Generate.tree(n, 2, IGraph::TREE_UNDIRECTED)

save_mod g.community_to_membership(merges, steps, n)

