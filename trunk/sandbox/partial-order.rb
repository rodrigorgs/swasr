#!/usr/bin/env ruby
# input: csv file, each line is a sequence of N numbers
# output: a partial order of the N positions
#
# Sample usage:
# find -name motifs.data | to_csv.rb > csv
# partial-order.rb csv

sequences = IO.readlines(ARGV[0]).map { |x| x.split(',').map{|y|y.to_f} }

orders = []
sequences.each do |sequence|
  ord = []
  sequence.each_with_index do |value, i|
    indices = (0..(sequence.size-1)).select { |j| sequence[j] < value }
    z = indices.map { |x| [i+1, x+1] }
    ord |= z
  end
  orders << ord unless ord.empty?
end

partial_order = orders.inject { |inter, set| inter & set }
p partial_order

require 'rgl/connected_components'
require 'rgl/adjacency'
require 'rgl/transitivity'
require 'rgl/dot'

g = RGL::DirectedAdjacencyGraph[*partial_order.flatten].transitive_reduction
g.write_to_graphic_file('png', 'partial-order')

#require 'network'
#
#n = Network.new
#n.add_edges(partial_order.map { |x, y| ["m#{x}", "m#{y}"] })
#n.save_dot("partial_order.dot")
