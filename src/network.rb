#!/usr/bin/env ruby
#
# Model of a directed network with one-level communities/modules/clusters
#

class Network
  attr_reader :nodes, :edges, :clusters

  def initialize
    @nodes    = []
    @edges    = []
    @clusters = []
  end

  def n(id)
    node = @nodes.find { |x| x.id == id }
    if node.nil?
      node = Node.new(id)
      @nodes << node
    end
    return node
  end

  def e(n1, n2)
    n1 = n(n1) unless n1.kind_of?(Node)
    n2 = n(n2) unless n2.kind_of?(Node)
    edge = @edges.find { |x| x.from == n1 && x.to == n2 }
    if edge.nil?
      edge = Edge.new(n1, n2)
      @edges << edge
      n1.out_edges << edge
      n2.in_edges << edge
    end
    return edge
  end

  def c(id)
    #puts "node: #{node}, cluster: #{cluster}"
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
end

class Cluster
  # Cuidado ao alterar o id para nao quebrar a unicidade!
  attr_accessor :id

  def initialize(id)
    @id = id
  end
end

class Edge
  attr_reader :from, :to

  def initialize(from, to)
    @from, @to = from, to
  end
end

# TODO: adicionar hash de atributos opcionais
class Node
  attr_reader :out_edges, :in_edges
  attr_accessor :cluster, :id

  def initialize(id)
    @id = id
    @out_edges = []
    @in_edges  = []
  end

  def _clusters(nodes)
    nodes.map { |n| n.cluster }.uniq
  end

  def in_nodes; @in_edges.map { |e| e.from }; end
  def out_nodes; @out_edges.map { |e| e.to }; end

  def degree; in_degree + out_degree; end
  def in_degree; @in_edges.size; end
  def out_degree; @out_edges.size; end
  def inner_degree; inner_in_degree + inner_out_degree; end
  def inner_in_degree; @in_edges.count { |e| e.from.cluster == @cluster }; end
  def inner_out_degree; @out_edges.count { |e| e.to.cluster == @cluster }; end
  def outer_degree; outer_in_degree + outer_out_degree; end
  def outer_in_degree; @in_edges.count { |e| e.from.cluster != @cluster }; end
  def outer_out_degree; @out_edges.count { |e| e.to.cluster != @cluster }; end
  def cluster_span; _clusters(in_nodes + out_nodes).size; end
  def in_cluster_span; _clusters(in_nodes).size; end
  def out_cluster_span; _clusters(out_nodes).size
  end
end
