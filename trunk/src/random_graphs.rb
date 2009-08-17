#!/usr/bin/env ruby

require 'network'
require 'fileutils'

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

# pick randomly one element from an array
def pick(array)
  array[rand(array.size)]
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

def bcrplus_game(size_limit, arch, alpha, beta, gamma, 
    delta_in, delta_out, prob_out)
  g = Network.new

  if arch.kind_of? String
    filename = arch
    arch = Network.new
    arch.load2(filename)
  end

  next_eid = 0
  arch.each_vertex do |module_|
    # remove auto-loops
    e = arch.edge?(module_, module_)
    arch.remove_edge e if e

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
      if rand < prob_out # external edge
        clusters = arch.nodes.select { |n| !n.out_nodes.empty? }
        clusters.map! { |n| g.cluster?(n.eid) }
        nodes = clusters.inject([]) { |union, c| union + c.nodes.to_a }
        v = choose_random(nodes.map{ |x| x.out_degree + delta_out}, nodes)

        arch_node = arch.node?(v.cluster.eid)
        clusters = arch_node.out_nodes.map { |n| g.cluster?(n.eid) }
        nodes = clusters.inject([]) { |union, c| union + c.nodes.to_a }
        nodes = nodes - v.out_nodes

        unless nodes.empty?
          w = choose_random(nodes.map{ |x| x.in_degree + delta_in }, nodes)
          g.edge!(v, w)
        end
      else # internal edge
        v = choose_random(g.nodes.map { |x| x.out_degree + delta_out }, g.nodes)
        nodes = v.cluster.nodes.to_a - [v] - v.out_nodes

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

# Choose one of the neighbors of ''node'' according to module-based
# preferential probability.
def choose_with_mbpa(g, node, alpha)
  # XXX discard node's neighbors?
  candidates = g.nodes - [node] - node.out_nodes
  probs = candidates.map do |n|
    if n.cluster == node.cluster
      n.degree * (1 + alpha) + 1
    else
      n.degree + 1
    end
  end
  return choose_random(probs, candidates)
end

# "Module-Based Large-Scale Software Evolution Based on Complex Networks",
# Tao Chen, Qing Gu, Shusen Wang, Xiaoan Chen, Daoxu Chen
#
# M = number of modules
def gu_game(size, p1, p2, p3, p4, e1, e2, e3, e4, alpha, num_modules)
  g = Network.new
  num_modules.times { |i| g.cluster!(i) }
  g.node!(0, 0)
  g.node!(1, 0)
  g.edge!(0, 1)

  sum = 0  
  event_prob_acc = [p1, p2, p3, p4].map { |x| sum += x; sum }
  while g.size < size
    event = choose_random_acc(event_prob_acc, [:p1, :p2, :p3, :p4])
    case event
    when :p1
      v = g.node!(g.size, pick(g.clusters))
      e1.times do
        w = choose_with_mbpa(g, v, alpha)
        g.edge!(v, w) if w
      end
    when :p2
      e2.times do
        v = pick(g.nodes)
        w = choose_with_mbpa(g, v, alpha)
        g.edge!(v, w) if w
      end
    when :p3
      e3.times do
        v = pick(g.nodes)
        edge = pick(v.out_edges) # XXX out_edges or edges?
        if edge
          w = choose_with_mbpa(g, v, alpha) 
          g.remove_edge(edge)
          g.edge!(v, w) if w
        end
      end
    when :p4
      e4.times do
        edge = pick(g.edges)
        g.remove_edge(edge) if edge
      end
    end    
  end
  return g
end

# Lancichinetti, Fortunato. Directed unweighted networks
def lf_game(n, kin, maxkin, mu, degexp, cexp, minc, maxc, seed, outfile)
  params = "-N #{n} -k #{kin} -maxk #{maxkin} -mu #{mu} "
  params += "-t1 #{degexp} " unless degexp.nil?
  params += "-t2 #{cexp} " unless cexp.nil?
  params += "-minc #{minc} " unless minc.nil?
  params += "-maxc #{maxc} " unless maxc.nil?

  puts params

  network = nil
  modules = nil
  Dir.chdir(Dir.tmpdir) do
    File.open('time_seed.dat', 'w') { |f| f.puts(seed || 0) }
    system "benchmark-directed #{params}"
    network = read_pairs("network.dat")
    network.map! { |a, b| [(a.to_i - 1).to_s, (b.to_i - 1).to_s] }
    modules = read_pairs("community.dat")
    modules.map! { |a, b| [(a.to_i - 1).to_s, (b.to_i - 1).to_s] }
    FileUtils.rm_f %w(network.dat community.dat statistics.dat)
  end
  puts_pairs(network, "#{outfile}.arc")
  puts_pairs(modules, "#{outfile}.mod")
end

begin
  require 'igraph'

  def save_igraph(g, basename)
    basename = basename[0..-2] if basename[-1..-1] == '.'

    File.open(basename + '.arc', 'w') do |f|
      g.each_edge(IGraph::EDGEORDER_ID) { |x, y| f.puts "#{x} #{y}" }
    end
    File.open(basename + '.mod', 'w') do |f|
      g.vcount.times { |i| f.puts "#{i} 0" }
    end
  end

  def erdos_renyi_nm(n, m, directed=true, basename=nil)
    g = IGraph::GenerateRandom.erdos_renyi_game(
      IGraph::ERDOS_RENYI_GNM,
      n,
      m,
      directed, # directed?
      false) # loops?

    save_igraph(g, basename) if basename
    
    return g
  end

  def configuration_model(out_deg, in_deg, basename=nil)
    g = IGraph::GenerateRandom::degree_sequence_game(out_deg, in_deg)
    save_igraph(g, basename) if basename
    return g
  end
rescue LoadError
  #puts "Could not load igraph."
end

#def igraph_ba_game(n, m)
#  IGraph::GenerateRandom.barabasi_game(n, m, false, true)
#end
## "Stochastic models for the web graph", Kumar et al. (2000)
#def copying_game
#end
## A Birth-death Dynamic Model of Scale-free Networks", Deo and Cami
## The paper shows a degree distribution plot for birth_prob = 0.9
#def birth_death_game(birth_prob, iterations)
#  g = DegreesDAG.new
#  g.add_vertex(0)
#  g.add_edge(0, 0)
#
#  iterations.times do
#    if rand <= birth_prob
#      new_vertex = g.size
#      g.add_vertex(new_vertex)
#      v = choose_random(g.vertices.map { |x| g.in_degree(x) })
#      g.add_edge(new_vertex, v)
#    else
#      to_delete = rand(g.size)
#      g.remove_vertex(g.vertices[to_delete])
#    end
#  end
#
#  return g
#end
## Valverde e Sole, "Network motifs in computational graphs: A case study in
## software architecture". Phys. Rev. E 72, 026107 (2005).
#def duplication_divergence_game(initial_size, divergence_prob, xlinking_prob)
#end
#
## Ravasz e Barabasi. "Hierarchical organization in complex networks" (2003).
#def hierarchical_network_game
#end
#
## out ~ -1.7*n^0.90  
## in  ~ -1.7*n^0.75  
##def degree_sequence_game(d_out, d_in)
##  IGraph::GenerateRandom.degree_sequence_game(d_out, d_in)
##end
# def rewire(g)
# end
