#!/usr/bin/env ruby

require 'igraph'

if __FILE__ == $0
  g = IGraph::GenerateRandom.barabasi_game(500, 3, false, true)
  g.each_edge(IGraph::EDGEORDER_ID) { |x, y| puts "depends #{x} #{y}" }
end
