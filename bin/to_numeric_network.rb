#!/usr/bin/env ruby

require 'network'

if ARGV.size < 4
  echo "Usage: #{File.basename $0} in-l1.pairs in-modules.pairs out-l1.pairs out-modules.pairs"
  echo ""
  echo "Outputs the network relabelled with numbers starting with 0"
  echo ""
end

net = Network.new ARGV[0], ARGV[1] #'l1.pairs', 'modules.pairs'

net.nodes.each_with_index { |n, idx| n.data.i = idx }
puts_pairs net.edges.map { |e| [e.from.data.i, e.to.data.i] }, ARGV[2] #'edges'
puts_pairs net.nodes.map { |n| [n.data.i, n.cluster.eid] }, ARGV[3] #'modules'
