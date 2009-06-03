#!/usr/bin/env ruby
#
# Model of a directed network with one-level communities/modules/clusters
#

require 'set'
require 'choice/lazyhash'
require 'grok'

class Network
  attr_reader :edges, :data

  def _init
    @nodes    = {}
    @clusters = {}
    @edges    = []
    @default_cluster = Cluster.new('DEFAULT')
    @data = Choice::LazyHash.new
  end

  def external_edges
    edges.select { |e| e.from.cluster != e.to.cluster }
  end


  def save(edges_file, modules_file, attr=nil)
    File.open(edges_file, "w") do |f|
      if attr.nil?
        edges.each { |e| f.puts "#{e.from.eid} #{e.to.eid}" }
      else
        edges.each { |e| f.puts "#{e.from.data.send(attr)} #{e.to.data.send(attr)}" }
      end
    end
    File.open(modules_file, "w") do |f|
      if attr.nil?
        nodes.each { |n| f.puts "#{n.eid} #{n.cluster.eid}" }
      else
        nodes.each { |n| f.puts "#{n.data.send(attr)} #{n.cluster.data.send(attr)}" }
      end
    end
  end

  def save2(basename, attributed=:eid)
    save(basename + '.arc', basename + '.mod')
  end

  def Network.load(*args)
    n = Network.new
    n.load(*args)
    return n
  end
  
  def Network.load2(*args)
    n = Network.new
    n.load2(*args)
    return n
  end


  # using PAIRS format
  def load(edges_file, modules_file)
    edges_file = read_pairs(edges_file) if edges_file.kind_of?(String)
    modules_file = read_pairs(modules_file) if modules_file.kind_of?(String)

    if !modules_file.nil?
      node_labels = modules_file.map { |a, b| a }
      if node_labels.uniq.size != node_labels.size
        raise 'There are nodes in more than one module' 
      end
    end

    set_clusters(modules_file) unless modules_file.nil?
    add_edges(edges_file) unless edges_file.nil?
  end

  def load2(basename)
    basename = basename[0..-2] if basename[-1..-1] == '.'
    load(basename + '.arc', basename + '.mod')
  end

  # Factory methods

  def new_node(eid)
    return Node.new(eid)
  end

  def new_edge(n1, n2)
    return Edge.new(n1, n2)
  end

  def new_cluster(eid)
    return Cluster.new(eid)
  end

  def new_network
    return Network.new
  end

  # ------ end Factory methods
  def edges_undirected
    edges.map { |e| [e.from, e.to].sort_by(&:eid) }.uniq.map { |a, b| new_edge(a, b) }
  end

  # using PAIRS format
  def initialize(_edges=nil, _modules=nil)
    _init
    load(_edges, _modules)
  end

  def node!(eid, cluster=nil)
    return eid if eid.kind_of?(Node)
    node = @nodes[eid]
    if node.nil?
      node = new_node(eid)
      set_cluster(node, cluster!(cluster))
      @nodes[eid] = node
    end
    return node
  end
 
  def node?(eid)
    return eid if eid.kind_of?(Node)
    return @nodes[eid]
  end

  def edge!(n1, n2, cluster1=nil, cluster2=nil)
    n1 = node!(n1, cluster!(cluster1))
    n2 = node!(n2, cluster!(cluster2))
    edge = if (n1.out_edges_map.size > n2.in_edges_map.size)
      n1.out_edges_map[n2]
    else
      n2.in_edges_map[n1]
    end
    if edge.nil?
      edge = new_edge(n1, n2)
      @edges << edge
      n1.out_edges_map[n2] = edge
      n2.in_edges_map[n1] = edge
    end
    return edge
  end

  def edge?(n1, n2)
    n1 = node?(n1)
    n2 = node?(n2)
    return nil if n1.nil? || n2.nil?
    return n1.out_edges_map[n2]
  end

  def cluster!(eid)
    return eid if eid.kind_of?(Cluster)
    return @default_cluster if eid.nil?
    cluster = @clusters[eid]
    if cluster.nil?
      cluster = new_cluster(eid)
      @clusters[eid] = cluster
    end
    return cluster
  end

  def cluster?(eid)
    return eid if eid.kind_of?(Cluster)
    return @default_cluster if eid.nil?
    return @clusters[eid]
  end

  def nodes
    @nodes.values
  end

  def clusters
    @clusters.values
  end

  def set_cluster(node, cluster)
    node = node!(node)
    cluster = cluster.nil? ? @default_cluster : cluster!(cluster)

    if cluster != node.cluster
      node.cluster._remove(node) if !node.cluster.nil? 
      cluster._add(node)
      node._cluster= cluster
    end
  end

  def add_edges(pairs)
    pairs.each { |n1, n2| edge!(n1, n2) }
    self
  end

  def set_clusters(pairs)
    pairs.each { |node, cluster| set_cluster(node, cluster) }
  end

  def size
    @nodes.size
  end

  def lift
    links = self.edges.map { |e| [e.from.cluster.eid, e.to.cluster.eid] }.uniq
    g = new_network
    self.clusters.each { |c| g.node!(c.eid) }
    g.add_edges(links.select { |l| l[0] != l[1] } )
    return g
  end

  # TODO: move to node
  def clustering_coefficient(node)
    node = node?(node)
    return 0 if node.nil?

    neighbors = node.neighbors
    return 0.0 if (neighbors.size < 2)
    nlinks = 0
    neighbors.each do |a|
      neighbors.each do |b|
        nlinks += 1 if a != b && edge?(a, b)
      end
    end

    return nlinks.to_f / (neighbors.size * (neighbors.size - 1))
  end

  def to_undirected!
    current_edges = edges.dup
    current_edges.each { |e| edge!(e.to, e.from) }
  end

  def remove_edge(e)
    return if e.nil?
    e.from.out_edges_map.delete(e.to)
    e.to.in_edges_map.delete(e.from)
    @edges.delete(e) 
  end

  def remove_node(n)
    n = node?(n)
    return if n.nil?
    n.edges.each { |e| remove_edge(e) }
    @nodes.delete(n.eid)
  end

  ###############################################

  def inspect
    ""
  end

  def to_dot
    s = "digraph G {\n"
    nodes.each { |n| s += "#{n.eid}[shape=box];\n" }
    edges.each { |e| s += "#{e.from.eid}->#{e.to.eid}\n" }
    s += "}"
  end

  def reduce_size(target_size)
    raise "size < target_size!" if size < target_size

    degree = 0
    while size > target_size
      extra = size - target_size
      set = nodes.select { |n| n.degree == degree }
      set[0..([extra,set.size].min - 1)].each { |n| remove_node(n) }
      degree += 1
    end
  end

  ############ RGL interface ####################
  
  def add_edge(n1, n2)
    edge!(n1, n2)
  end
  
  def add_vertex(v)
    node!(v)
  end

  def vertices
    nodes
  end

  def in_degree(v)
    node!(v).in_degree
  end

  def out_degree(v)
    node!(v).out_degree
  end

  def each_vertex(&block)
    nodes.each { |v| block.call(v) }
  end

  def adjacent_vertices(v)
    node!(v).out_edges_map.values
  end

end

class Cluster
  # Cuidado ao alterar o eid para nao quebrar a unicidade!
  attr_accessor :data
  attr_reader :eid, :nodes
 
  def initialize(eid)
    @eid = eid
    @data = Choice::LazyHash.new
    @nodes = Set.new
  end

  def _add(node)
    @nodes << node
  end

  def _remove(node)
    @nodes.delete(node)
  end

  def size
    @nodes.size
  end
end

class Edge
  attr_reader :from, :to
  attr_accessor :weight, :data
  
  def initialize(from, to)
    @from, @to = from, to
    @data = Choice::LazyHash.new
  end

  def to_s
    "#{@from.to_s}->#{@to.to_s}"
  end
end

class Node
  attr_reader :cluster, :eid
  attr_reader :out_edges_map, :in_edges_map, :data
  
  def initialize(eid)
    @eid = eid
    @out_edges_map = {}
    @in_edges_map  = {}
    @data = Choice::LazyHash.new
  end

  def to_s
    @eid
  end

  def _cluster=(cluster)
    @cluster = cluster
  end

  def out_edges
    @out_edges_map.values
  end

  def in_edges
    @in_edges_map.values
  end

  def edges
    out_edges + in_edges
  end

  def _clusters(nodes)
    nodes.map { |n| n.cluster }.uniq
  end

  def in_nodes; @in_edges_map.map { |n, e| n }; end
  def out_nodes; @out_edges_map.map { |n, e| n }; end
  def in_edges; @in_edges_map.values; end
  def out_edges; @out_edges_map.values; end

  def degree; neighbors.size; end
  def in_degree; @in_edges_map.size; end
  def out_degree; @out_edges_map.size; end
  def internal_degree; neighbors.count { |n| n.cluster == @cluster }; end
  def internal_in_degree; @in_edges_map.count { |n, e| n.cluster == @cluster }; end
  def internal_out_degree; @out_edges_map.count { |n, e| n.cluster == @cluster }; end
  def external_degree; neighbors.count { |n| n.cluster != @cluster }; end
  def external_in_degree; @in_edges_map.count { |n, e| n.cluster != @cluster }; end
  def external_out_degree; @out_edges_map.count { |n, e| n.cluster != @cluster }; end
  def cluster_span; _clusters(in_nodes + out_nodes).size; end
  def in_cluster_span; _clusters(in_nodes).size; end
  def out_cluster_span; _clusters(out_nodes).size; end

  def neighbors
    (out_edges.map { |e| e.to } + in_edges.map { |e| e.from}).uniq
  end

end

# Network in which network are labelled by numbers.
# The efficiency is improved only insignificantly.
class NumberedNetwork < Network
  attr_accessor :start_from

  def _init
    @nodes    = []
    @clusters = []
    @edges    = []
    @default_cluster = Cluster.new('DEFAULT')
    @data = Choice::LazyHash.new
    @start_from = nil
  end

  def new_network
    return NumberedNetwork.new
  end
  
  def size
    @nodes.size - @start_from
  end

  def nodes
    @nodes[@start_from..-1]
  end

  def clusters
    @clusters
  end
end

