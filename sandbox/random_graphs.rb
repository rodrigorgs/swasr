#!/usr/bin/env ruby

require 'rgl/adjacency'
require 'rgl/bidirectional'
require 'igraph'
# g.each_edge(IGraph::EDGEORDER_ID) { |x, y| puts "depends #{x} #{y}" }

# choose one index, with probability proportional to its weight
def choose_random_acc(acc_weights)
  n = rand * acc_weights[-1]
  acc_weights.each_with_index { |x, i| return i if x > n }
  return acc_weights.size - 1
end

def choose_random(weights)
  sum = 0
  acc_weights = weights.map { |x| sum += x; sum } #+ [sum + 1]

  return choose_random_acc(acc_weights)
end

class RGL::DirectedAdjacencyGraph
  def in_degree(v)
    i = 0
    self.each_edge { |a, b| i += 1 if b == v }
    return i
  end
end

# "Directed Scale-Free Graphs", Bollobas et al.
# Suggested parameters for a web graph (for which gamma_in = 2.1 and
# gamma_out = 2.7)
# * alpha =     0.41
# * beta =      0.49 .. 0.59
# * gamma =     0.10 .. 0.00
# * delta_in =  0.00 .. 0.24
# * delta_out = 0.00
def bollobas_game(n, alpha, beta, gamma, delta_in, delta_out)
  sum = 0
  event_prob_acc = [alpha, beta, gamma].map { |x| sum += x; sum }

  g = RGL::DirectedAdjacencyGraph.new
  g.add_edge(0, 0)
  1.upto(n - 1) do |i|
    event = choose_random_acc(event_prob_acc)
    case event
    when 0
      # add a new vertex v together with an edge from v to an existing 
      # vertex w, where w is chosen according to d_in + delta_in
      vertex_prob = g.vertices.map { |x| g.in_degree(x) + delta_in }
      w = choose_random(vertex_prob)
      g.add_vertex(i)
      g.add_edge(i, g.vertices[w])
    when 1
      # add an edge from an existing vertex v to an existing vertex w, where
      # v and w are chosen independently, v according to d_out + delta_out,
      # and w according to d_in + delta_in
      v = choose_random(g.vertices.map { |x| g.out_degree(x) + delta_out })
      w = choose_random(g.vertices.map { |x| g.in_degree(x) + delta_in })
      g.add_edge(g.vertices[v], g.vertices[w])
    when 2
      # add a new vertex w and an edge from an existing v to w, where v is
      # chosen according to d_out + delta_out
      vertex_prob = g.vertices.map { |x| g.out_degree(x) + delta_out }
      v = choose_random(vertex_prob)
      g.add_vertex(i)
      g.add_edge(g.vertices[v], i)
    end
  end

  return g
end

# Barabasi-Albert model. TODO: use parameters m0, m
#def ba_game(m0, m)
#  g = RGL::DirectedAdjacencyGraph.new
#  g.add_edge(0, 1)
#
#  2.upto(m - 1) do |node|
#    g.add_vertex node
#    sum_k_j = (0..node-1).inject(0) { |sum, i| sum + g.out_degree(i) }
#    0.upto(node - 1) do |i|
#      p_i = g.out_degree(i).to_f / sum_k_j
#      g.add_edge node, i if rand < p_i
#    end
#  end
#
#  return g
#end
#
## Barabasi-Albert model, using a sequence of out-degrees.
#def ba_game(m0, outseq)
#end
#
#def igraph_ba_game(n, m)
#  IGraph::GenerateRandom.barabasi_game(n, m, false, true)
#end
#
## "Stochastic models for the web graph", Kumar et al.
#def copying_game
#end
#
#
## A Birth-death Dynamic Model of Scale-free Networks", Deo and Cami
#def birth_death_game
#end
#
## out ~ -1.7*n^0.90  
## in  ~ -1.7*n^0.75  
#def degree_sequence_game(d_out, d_in)
#  IGraph::GenerateRandom.degree_sequence_game(d_out, d_in)
#end
#
#if __FILE__ == $0
#
#  require 'rgl/dot'
#
#  #g = generate_ba_graph(2, 100)
#  #g.write_to_graphic_file('png')
#  
#end

