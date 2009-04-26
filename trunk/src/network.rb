#!/usr/bin/env ruby
#
# Model of a directed network with one-level communities/modules/clusters
#

require 'choice/lazyhash'

class Network
  attr_reader :edges, :clusters, :data
  
  def initialize
    @nodes    = {}
    @edges    = []
    @clusters = []
    @data = Choice::LazyHash.new
  end

  def n(id)
    return id if id.kind_of?(Node)
    node = @nodes[id]
    if node.nil?
      node = Node.new(id)
      @nodes[id] = node
    end
    return node
  end

  def e(n1, n2)
    n1 = n(n1) 
    n2 = n(n2)
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

  def nodes
    @nodes.values
  end

  def c(id)
    cluster = @clusters.find { |x| x.id == id }
    if cluster.nil?
      cluster = Cluster.new(id)
      @clusters << cluster
    end
    return cluster
  end

  def set_cluster(node, cluster)
    node = n(node) unless node.kind_of?(Node)
    cluster = c(cluster) unless cluster.kind_of?(Cluster)

    node.cluster = cluster
  end

  def add_edges(pairs)
    pairs.each { |n1, n2| e(n1, n2) }
    self
  end

  def set_clusters(pairs)
    pairs.each { |node, cluster| set_cluster(n(node), c(cluster)) }
  end

  ############ RGL interface ####################
  
  def add_edge(n1, n2)
    e(n1, n2)
  end
  
  def add_vertex(v)
    n(v)
  end

  def vertices
    nodes
  end

  def size
    @nodes.size
  end

  def in_degree(v)
    n(v).in_degree
  end

  def out_degree(v)
    n(v).out_degree
  end

  def each_vertex(&block)
    nodes.each { |v| block.call(v) }
  end

  def adjacent_vertices(v)
    n(v).out_edges_map.values
  end

end

class Cluster
  # Cuidado ao alterar o id para nao quebrar a unicidade!
  attr_accessor :id, :data
  
  def initialize(id)
    @id = id
    @data = Choice::LazyHash.new
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
  attr_accessor :cluster, :id
  attr_reader :out_edges_map, :in_edges_map, :data
  
  def initialize(id)
    @id = id
    @out_edges_map = {}
    @in_edges_map  = {}
    @data = Choice::LazyHash.new
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

  def degree; in_degree + out_degree; end
  def in_degree; @in_edges_map.size; end
  def out_degree; @out_edges_map.size; end
  def inner_degree; inner_in_degree + inner_out_degree; end
  def inner_in_degree; @in_edges_map.count { |n, e| n.cluster == @cluster }; end
  def inner_out_degree; @out_edges_map.count { |n, e| n.cluster == @cluster }; end
  def outer_degree; outer_in_degree + outer_out_degree; end
  def outer_in_degree; @in_edges_map.count { |n, e| n.cluster != @cluster }; end
  def outer_out_degree; @out_edges_map.count { |n, e| n.cluster != @cluster }; end
  def cluster_span; _clusters(in_nodes + out_nodes).size; end
  def in_cluster_span; _clusters(in_nodes).size; end
  def out_cluster_span; _clusters(out_nodes).size
  end
end
