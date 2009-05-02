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

  def edges_undirected
    edges.map { |e| [e.from, e.to].sort_by(&:eid) }.uniq.map { |a, b| Edge.new(a, b) }
  end

  # using PAIRS format
  def initialize(_edges=nil, _modules=nil)
    _init
    _edges = read_pairs(_edges) if _edges.kind_of?(String)
    _modules = read_pairs(_modules) if _modules.kind_of?(String)
    set_clusters(_modules) unless _modules.nil?
    add_edges(_edges) unless _edges.nil?
  end

  def node!(eid, cluster=nil)
    return eid if eid.kind_of?(Node)
    node = @nodes[eid]
    if node.nil?
      node = Node.new(eid)
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
      edge = Edge.new(n1, n2)
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
      cluster = Cluster.new(eid)
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
    g = Network.new
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
