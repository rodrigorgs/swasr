#!/usr/bin/env ruby

require 'igraph'
require 'graph_metrics'

if __FILE__ == $0
  filename = ARGV[0]
  if filename.nil?
    puts "Usage: #{File.basename($0)} filename

    Where filename is the name of a RSF file.
    Generates a graph with the same degree sequence of the RSF file.
    "
    exit 1
  end

  pairs = read_rsf_pairs(filename)
  degrees = out_in_degrees(pairs)
  d_out = degrees.map { |x, y| x }
  d_in = degrees.map { |x, y| y }

  g = IGraph::GenerateRandom.degree_sequence_game(d_out, d_in)
  g.each_edge(IGraph::EDGEORDER_ID) { |x, y| puts "depends #{x} #{y}" }
end
