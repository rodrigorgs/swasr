#!/usr/bin/env ruby

require 'graph'
require 'network'

# g.each_edge(IGraph::EDGEORDER_ID) { |x, y| puts "depends #{x} #{y}" }

#require 'random/mersenne_twister'
#$mt = Random::MersenneTwister.new 4357
#module Kernel
#  def rand(*args)
#    $mt.rand(*args)
#  end
#end

# choose one index, with probability proportional to its weight
def choose_random_acc(acc_weights, labels=(0..acc_weights.size-1).to_a)
  return nil if acc_weights.nil? || acc_weights.empty?

  n = rand * acc_weights[-1]
  # XXX optimize using binary search
  acc_weights.each_with_index { |x, i| return labels[i] if x > n }
  return labels[acc_weights.size - 1]
end

# XXX optimize (maybe avoid using this function)
def choose_random(weights, labels=(0..weights.size-1).to_a)
  return nil if weights.nil? || weights.empty?

  sum = 0
  acc_weights = weights.map { |x| sum += x; sum } #+ [sum + 1]

  return choose_random_acc(acc_weights, labels)
end

# "Directed Scale-Free Graphs", Bollobas et al.
# Suggested parameters for a web graph (for which gamma_in = 2.1 and
# gamma_out = 2.7)
# * alpha =     0.41
# * beta =      0.49 .. 0.59
# * gamma =     0.10 .. 0.00
# * delta_in =  0.00 .. 0.24
# * delta_out = 0.00
#
# Example:
#   bollobas_game(100, 0.41, 0.49, 0.10, 0.00, 0.00)
def bollobas_game(iterations, alpha, beta, gamma, delta_in, delta_out, base_index=0)
  sum = 0
  event_prob_acc = [alpha, beta, gamma].map { |x| sum += x; sum }

  g = DegreesDAG.new(Set) # XXX or Array?
  g.add_edge(base_index + 0, base_index + 1)
  base_index += 2
  iterations.times do
    event = choose_random_acc(event_prob_acc)
    case event
    when 0
      # add a new vertex v together with an edge from v to an existing 
      # vertex w, where w is chosen according to d_in + delta_in
      vertex_prob = g.vertices.map { |x| g.in_degree(x) + delta_in }
      w = g.vertices[choose_random(vertex_prob)]
      v = base_index
      g.add_vertex(v)
      g.add_edge(v, w)
      base_index += 1
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
      v = g.vertices[choose_random(vertex_prob)]
      w = base_index
      g.add_vertex(w)
      g.add_edge(v, w)
      base_index += 1
    end
  end

  return g
end

def bollobas2_game(nodes, alpha, beta, gamma, delta_in=0, delta_out=0, base_index=0)
  sum = 0
  event_prob_acc = [alpha, beta, gamma].map { |x| sum += x; sum }

  g = Network.new
  g.add_edge(base_index + 0, base_index + 1)
  base_index += 2
  while g.size < nodes
    event = choose_random_acc(event_prob_acc)
    case event
    when 0
      # add a new vertex v together with an edge from v to an existing 
      # vertex w, where w is chosen according to d_in + delta_in
      vertex_prob = g.nodes.map { |x| g.in_degree(x) + delta_in }
      w = g.nodes[choose_random(vertex_prob)]
      v = base_index
      g.add_vertex(v)
      g.add_edge(v, w)
      base_index += 1
    when 1
      # add an edge from an existing vertex v to an existing vertex w, where
      # v and w are chosen independently, v according to d_out + delta_out,
      # and w according to d_in + delta_in
      v = choose_random(g.nodes.map { |x| g.out_degree(x) + delta_out })
      w = choose_random(g.nodes.map { |x| g.in_degree(x) + delta_in })
      g.add_edge(g.nodes[v], g.nodes[w])
    when 2
      # add a new vertex w and an edge from an existing v to w, where v is
      # chosen according to d_out + delta_out
      vertex_prob = g.nodes.map { |x| g.out_degree(x) + delta_out }
      v = g.nodes[choose_random(vertex_prob)]
      w = base_index
      g.add_vertex(w)
      g.add_edge(v, w)
      base_index += 1
    end
  end

  return g
end

# Barabasi-Albert model. TODO: Implement (use parameters m0, m)
def ba_game(m0, m)
  g = DegreesDAG.new
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
#
## Barabasi-Albert model, using a sequence of out-degrees.
#def ba_game(m0, outseq)
#end

#def igraph_ba_game(n, m)
#  IGraph::GenerateRandom.barabasi_game(n, m, false, true)
#end

## "Stochastic models for the web graph", Kumar et al. (2000)
#def copying_game
#end
#
#

# A Birth-death Dynamic Model of Scale-free Networks", Deo and Cami
# The paper shows a degree distribution plot for birth_prob = 0.9
def birth_death_game(birth_prob, iterations)
  g = DegreesDAG.new
  g.add_vertex(0)
  g.add_edge(0, 0)

  iterations.times do
    if rand <= birth_prob
      new_vertex = g.size
      g.add_vertex(new_vertex)
      v = choose_random(g.vertices.map { |x| g.in_degree(x) })
      g.add_edge(new_vertex, v)
    else
      to_delete = rand(g.size)
      g.remove_vertex(g.vertices[to_delete])
    end
  end

  return g
end

def graph_union(g1, g2)
  g = DegreesDAG.new
  
  g.add_vertices(*g1.vertices)
  g.add_edges(*g2.edges)
  n = g1.size
  g.add_vertices(*g2.vertices.map{ |x| x + n })
  g.add_edges(*g2.edges.map{ |e| [e.source + n, e.target + n] })

  return g
end

# g1 and g2's vertices must be numbers 
def two_layered_graph(g1, g2, n_links)
  g = graph_union(g1, g2)
  n = 1 + g1.vertices.inject(0) { |max, v| v > max && max || v }

  vertices = g.vertices.partition { |x| x < n }
  
  n_links.times do
    v = choose_random(vertices[0].map { |x| g.in_degree(x) })
    w = choose_random(vertices[1].map { |x| g.out_degree(x) })
    g.add_edge(v, w)
  end

  return g
end

# == Algoritmo
#
# O grafo inicial contém um vértice com auto-laço para cada módulo na 
# arquitetura. Então, a cada iteração, um entre três eventos pode ocorrer.
#
# Com probabilidade alpha é adicionado um novo vértice v, que se liga a um
# vértice existente, w, escolhido de acordo com delta_in + grau de entrada de 
# w. O vértice v passa a pertencer ao mesmo módulo de w.
#
# Com probabilidade gama é a mesma coisa, com a diferença de que a ligação
# é no sentido w -> v.
#
# Com probabilidade beta, é adicionada uma aresta entre dois vértices 
# existentes, v -> w. 
# * v é escolhido de acordo com delta_out + grau de saída de v
# * w é escolhido dentre os vértices dos outros módulos com os quais v pode 
# se ligar, de acordo com delta_in + grau de entrada de w
#
# == Considerações
#
# Cada vértice obrigatoriamente se liga a pelo menos um vértice do mesmo
# módulo que ele, o que não é verdade se considerarmos pacotes Java como
# módulos. Isso significa que ou este modelo não é adequado ou pacotes
# Java não são bem módulos arquiteturais.
#
# TODO: na hora de ligar dois vertices v e w de modulos diferentes, 
# considerar numero de arestas que entram em v a partir de uma aresta do
# mesmo modulo e tambem o numero de arestas que saem de v para outro modulo.
# 
# TODO: no caso beta, será que v não seria escolhido com in e w com out?
#
# TODO: o caso beta não deveria permitir ligações dentro do módulo?
#
# DEPRECATED. Use rodrigo2008_game instead.
def design_from_architecture(iterations, arch, alpha, beta, gamma, 
    delta_in, delta_out)

  modules = Hash.new
  # g is the design
  g = DegreesDAG.new(Set)

  # Creates a vertex with a self-loop for each module in arch
  v = 0
  arch.each_vertex do |m|
    g.add_edge v, v
    modules[v] = m
    v += 1
  end

  sum = 0
  event_prob_acc = [alpha, beta, gamma].map { |x| sum += x; sum }

  iterations.times do
    event = choose_random_acc(event_prob_acc, [:alpha, :beta, :gamma])
    case event
    when :alpha
      # add a new vertex v together with an edge from v to an existing 
      # vertex w, where w is chosen according to d_in + delta_in
      vertex_prob = g.vertices.map { |x| g.in_degree(x) + delta_in }
      w = g.vertices[choose_random(vertex_prob)]
      v = g.size
      g.add_vertex(v)
      g.add_edge(v, w)
      modules[v] = modules[w]
    when :beta
      # add an edge from an existing vertex v to an existing vertex w, where
      # v and w are chosen independently, v according to d_out + delta_out,
      # and w according to d_in + delta_in
      v = choose_random(g.vertices.map { |x| g.out_degree(x) + delta_out })
      v = g.vertices[v]
      adjacent_modules = arch.adjacent_vertices(modules[v])

      vertices = g.vertices.select { |x| adjacent_modules.include? modules[x] }
      unless vertices.empty?
        w = choose_random(vertices.map { |x| g.in_degree(x) + delta_in })
        w = vertices[w]

        g.add_edge(v, w)
      end
    when :gamma
      # add a new vertex w and an edge from an existing v to w, where v is
      # chosen according to d_out + delta_out
      vertex_prob = g.vertices.map { |x| g.out_degree(x) + delta_out }
      v = g.vertices[choose_random(vertex_prob)]
      w = g.size
      g.add_vertex(w)
      g.add_edge(v, w)
      modules[w] = modules[v]
    end
  end

  return [g, modules]
end

def rodrigo2008_game(size_limit, arch, alpha, beta, gamma, 
    delta_in, delta_out)
  g = Network.new

  next_eid = 0
  arch.each_vertex do |module_|
    v = g.node!(next_eid, module_.eid)
    g.edge!(v, v)
    next_eid += 1
  end

  sum = 0  
  event_prob_acc = [alpha, beta, gamma].map { |x| sum += x; sum }
  while g.size < size_limit
    event = choose_random_acc(event_prob_acc, [:alpha, :beta, :gamma])

    case event
    when :alpha
      w = choose_random(g.nodes.map{ |x| x.in_degree + delta_in }, g.nodes)
      v = g.node!(next_eid, w.cluster)
      g.edge!(v, w)
    when :beta
      v = choose_random(g.nodes.map{ |x| x.out_degree + delta_out}, g.nodes)
      adjacent_clusters = arch.node?(v.cluster.eid).out_nodes.map { |m| g.cluster?(m.eid) } #.select { |c| c != v.cluster }
      candidates = g.nodes.select { |x| adjacent_clusters.include? x.cluster }
      unless candidates.empty?
        w = choose_random(candidates.map{ |x| x.in_degree + delta_in }, candidates)
        g.edge!(v, w)
      end
    when :gamma
      v = choose_random(g.nodes.map{ |x| x.out_degree + delta_out }, g.nodes)
      w = g.node!(next_eid, v.cluster)
      g.edge!(v, w)
    end
    next_eid += 1 if (event == :alpha || event == :gamma)
  end

  return g
end

def souza2009_game(size_limit, arch, alpha, beta, gamma, 
    delta_in, delta_out, prob_out)
  g = Network.new

  next_eid = 0
  arch.each_vertex do |module_|
    v = g.node!(next_eid, module_.eid)
    g.edge!(v, v)
    next_eid += 1
  end

  #prob_out = mixing.to_f / beta

  sum = 0  
  event_prob_acc = [alpha, beta, gamma].map { |x| sum += x; sum }
  while g.size < size_limit
    event = choose_random_acc(event_prob_acc, [:alpha, :beta, :gamma])

    case event
    when :alpha
      w = choose_random(g.nodes.map{ |x| x.in_degree + delta_in }, g.nodes)
      v = g.node!(next_eid, w.cluster)
      g.edge!(v, w)
    when :beta
      if rand < prob_out # external edge
        clusters_with_neighbors = arch.nodes.select { |n| !n.neighbors.empty? }
        clusters_with_neighbors.map! { |n| g.cluster?(n.eid) }
        nodes = clusters_with_neighbors.inject([]) { |union, c| union + c.nodes.to_a }
        v = choose_random(nodes.map{ |x| x.out_degree + delta_out}, nodes)
        adjacent_clusters = arch.node?(v.cluster.eid).out_nodes.map { |m| g.cluster?(m.eid) }.select { |c| c != v.cluster }
        candidates = g.nodes.select { |x| adjacent_clusters.include? x.cluster }
        unless candidates.empty?
          w = choose_random(candidates.map{ |x| x.in_degree + delta_in }, candidates)
          g.edge!(v, w)
        end
      else # internal edge
        v = choose_random(g.nodes.map { |x| x.out_degree + delta_out }, g.nodes)
        nodes = v.cluster.nodes.to_a - [v]

        unless nodes.empty?
          w = choose_random(nodes.map { |x| x.in_degree + delta_in }, nodes)
          g.edge!(v, w)
        end
      end
    when :gamma
      v = choose_random(g.nodes.map{ |x| x.out_degree + delta_out }, g.nodes)
      w = g.node!(next_eid, v.cluster)
      g.edge!(v, w)
    end
    next_eid += 1 if (event == :alpha || event == :gamma)
  end

  return g
end

#require 'test/unit'
#include Test::Unit::Assertions
# Assigns each module_graph to a node in arch_graph
# repeat
#   Add an edge between two vertices in distinct module_graph only if the
#   corresponding vertices in arch_graph are connected
#
# XXX: the graphs arch and module_graphs must have vertices 0..g.size-1
def preferential_arch(iterations, arch, subgraphs)
  puts "preferential arch"
  g = DegreesDAG.new
  subgraphs.each do |graph| 
    g.add_vertices(*graph.vertices)
    g.add_edges(*graph.edges)
  end
  
  modules = arch.vertices.sort
  
  modules_out_degree = Hash.new(0)
  modules_in_degree = Hash.new(0)

  iterations.times do |iter|
    puts iter if iter % 100 == 0

    m1 = choose_random(modules.map { |m| 0.1 + modules_out_degree[m] }, modules)
    next if m1.nil?
    sg1 = subgraphs[m1]

    neighbors = arch.adjacent_vertices(m1)

    m2 = choose_random(neighbors.map { |m| 0.1 + modules_in_degree[m] }, neighbors)
    next if m2.nil?
    sg2 = subgraphs[m2]
    
    # assert arch.has_edge?(m1, m2)

    v = choose_random(sg1.vertices.map { |x| sg1.in_degree(x) }, sg1.vertices)
    next if v.nil?
    w = choose_random(sg2.vertices.map { |x| sg2.out_degree(x) }, sg2.vertices)
    next if w.nil?

    g.add_edge v, w

    modules_out_degree[m1] += 1
    modules_in_degree[m2] += 1
  end

  return g
end

# def rewire(g)
# end

# Valverde e Sole, "Network motifs in computational graphs: A case study in
# software architecture". Phys. Rev. E 72, 026107 (2005).
def duplication_divergence_game(initial_size, divergence_prob, xlinking_prob)
end

# Ravasz e Barabasi. "Hierarchical organization in complex networks" (2003).
def hierarchical_network_game
end

# out ~ -1.7*n^0.90  
# in  ~ -1.7*n^0.75  
#def degree_sequence_game(d_out, d_in)
#  IGraph::GenerateRandom.degree_sequence_game(d_out, d_in)
#end

#if __FILE__ == $0
#
#  require 'rgl/dot'
#
#  #g = generate_ba_graph(2, 100)
#  #g.write_to_graphic_file('png')
#  
#end

require 'igraph'

def erdos_renyi_nm(n, m, file=nil, file2=nil)
  g = IGraph::GenerateRandom.erdos_renyi_game(
    IGraph::ERDOS_RENYI_GNM,
    n,
    m,
    false,
    false)

  unless file.nil?
    File.open(file, 'w') do |f|
      g.each_edge(IGraph::EDGEORDER_ID) { |x, y| f.puts "#{x} #{y}" }
    end
    unless file2.nil?
      File.open(file2, 'w') do |f|
        n.times { |i| f.puts "#{i} 0" }
      end
    end
  end
  
  return g
end
