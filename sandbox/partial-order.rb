#!/usr/bin/env ruby

systems = IO.readlines('motifs-orders').map { |x| x.split(',').map{|y|y.to_i} }


orders = []
systems.each do |indices|
  ord = []
  indices.each_with_index do |index, i|
    z = indices[(i+1)..-1].map { |x| [index, x] }
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
