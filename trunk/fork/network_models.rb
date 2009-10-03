#!/usr/bin/env ruby

require 'network_base'
require 'fileutils'
require 'tmpdir'
require 'open3'

##############################################################################

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

# Choose one of the neighbors of ''node'' according to module-based
# preferential probability.
def choose_with_mbpa(g, node, alpha)
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

##############################################################################

def generate_bcrplus(params)
  p1 = params[:p1]
  p2 = params[:p2]
  p3 = params[:p3]
  delta_in = params[:din]
  delta_out = params[:dout]
  prob_out = params[:mu]
  seed = params[:seed]
  arch_arc = params[:arc_architecture]
  arch_mod = params[:mod_architecture]
  size_limit = params[:n]

  srand(seed)

  g = Network.new

  arch = Network.new.load_from_string(arch_arc, arch_mod)

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
  event_prob_acc = [p1, p2, p3].map { |x| sum += x; sum }
  while g.size < size_limit
    event = choose_random_acc(event_prob_acc, [:node_out, :node_in, :edge])

    case event
    when :node_out
      w = choose_random(g.nodes.map{ |x| x.in_degree + delta_in }, g.nodes)
      v = g.node!(next_eid, w.cluster)
      g.edge!(v, w)
    when :node_in
      v = choose_random(g.nodes.map{ |x| x.out_degree + delta_out }, g.nodes)
      w = g.node!(next_eid, v.cluster)
      g.edge!(v, w)
    when :edge
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
    end
    next_eid += 1 if (event == :node_out || event == :node_in)
  end

  return [g.arc_string, g.mod_string]
end


# "Module-Based Large-Scale Software Evolution Based on Complex Networks",
# Tao Chen, Qing Gu, Shusen Wang, Xiaoan Chen, Daoxu Chen
#
# M = number of modules

def generate_cgw(params)
  cmd = "cgw #{params[:n]}\
,#{params[:p1]}\
,#{params[:p2]}\
,#{params[:p3]}\
,#{params[:p4]}\
,#{params[:e1]}\
,#{params[:e2]}\
,#{params[:e3]}\
,#{params[:e4]}\
,#{params[:alpha]}\
,#{params[:m]}\
,#{params[:seed]}"

  ret = nil
  Open3.popen3(cmd) { |_, stdout, stderr| ret = [stdout.read, stderr.read] }
  return ret
end

# Lancichinetti, Fortunato. Directed unweighted networks
def generate_lf(params)
  cmd_params = "-N #{params[:n]} -k #{params[:avgk]} -maxk #{params[:maxk]} -mu #{params[:mixing]} "
  cmd_params += "-t1 #{params[:expdegree]} " unless params[:expdegree].nil?
  cmd_params += "-t2 #{params[:expsize]} " unless params[:expsize].nil?
  cmd_params += "-minc #{params[:minm]} " unless params[:minm].nil?
  cmd_params += "-maxc #{params[:maxm]} " unless params[:maxm].nil?
  seed = params[:seed] || 0

  network = nil
  modules = nil
  Dir.chdir(Dir.tmpdir) do
    File.open('time_seed.dat', 'w') { |f| f.puts(seed) }
    system "benchmark-directed #{cmd_params}"
    network = read_pairs("network.dat")
    network.map! { |a, b| [(a.to_i - 1).to_s, (b.to_i - 1).to_s] }
    modules = read_pairs("community.dat")
    modules.map! { |a, b| [(a.to_i - 1).to_s, (b.to_i - 1).to_s] }
    FileUtils.rm_f %w(network.dat community.dat statistics.dat)
  end

  return [pairs_to_string(network), pairs_to_string(modules)]
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

  #def igraph_ba_game(n, m)
  #  IGraph::GenerateRandom.barabasi_game(n, m, false, true)
  #end
rescue LoadError
  #puts "Could not load igraph."
end

