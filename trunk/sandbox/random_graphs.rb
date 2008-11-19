#!/usr/bin/env ruby

require 'rgl/adjacency'
require 'igraph'
# g.each_edge(IGraph::EDGEORDER_ID) { |x, y| puts "depends #{x} #{y}" }

# Barabasi-Albert model. TODO: use parameters m0, m
def ba_game(m0, m)
  g = RGL::AdjacencyGraph.new
  g.add_edge(0, 1)

  2.upto(m - 1) do |node|
    g.add_vertex node
    sum_k_j = (0..node-1).inject(0) { |sum, i| sum + g.out_degree(i) }
    0.upto(node - 1) do |i|
      p_i = g.out_degree(i).to_f / sum_k_j
      g.add_edge node, i if rand < p_i
    end
  end

  return g
end

# Barabasi-Albert model, using a sequence of out-degrees.
def ba_game(m0, outseq)
end

def igraph_ba_game(n, m)
  IGraph::GenerateRandom.barabasi_game(n, m, false, true)
end

# "Stochastic models for the web graph", Kumar et al.
def copying_game
end

# "Directed Scale-Free Graphs", Bollobas et al.
def bollobas_game(alpha, beta, gamma, din, dout)
end

# A Birth-death Dynamic Model of Scale-free Networks", Deo and Cami
def birth_death_game
end

def degree_sequence_game(d_out, d_in)
	IGraph::GenerateRandom.degree_sequence_game(d_out, d_in)
end

if __FILE__ == $0

  require 'rgl/dot'

  #g = generate_ba_graph(2, 100)
  #g.write_to_graphic_file('png')
  
end

