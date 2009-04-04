#!/usr/bin/env ruby
#
# Model of a directed network with one-level communities/modules/clusters
#

class Network
  attr_accessor :nodes

  def n(id)
    node = @nodes.find { |x| x.id == id }
    if node.nil?
      node = Node.new(id)
      @nodes << node
    end
    return node
  end


end

class Cluster
  attr_accessor :id
end

# TODO: trocar in_/out_neighbors por in_/out_edges e cria classe Edge.
#       Desta forma sera possivel atribuir pesos e tipos a arestas.
# TODO: adicionar hash de atributos opcionais
class Node
  attr_accessor :out_neighbors, :in_neighbors
  attr_accessor :cluster, :id

  def _clusters(nodes)
    nodes.map { |n| n.cluster }.uniq
  end

  def <<(other)
    
  end

  def degree; in_degree + out_degree; end
  def in_degree; @in_neighbors.size; end
  def out_degree; @out_neighbors; end
  def inner_degree; inner_in_degree + inner_out_degree; end
  def inner_in_degree; @in_neighbors.count { |n| n.cluster == @cluster }; end
  def inner_out_degree; @out_neighbors.count { |n| n.cluster == @cluster }; end
  def outer_degree; outer_in_degree + outer_out_degree; end
  def outer_in_degree; @in_neighbors.count { |n| n.cluster != @cluster }; end
  def outer_out_degree; @out_neighbors.count { |n| n.cluster != @cluster }; end
  def cluster_span; _clusters(@in_neighbors + @out_neighbors).size; end
  def in_cluster_span; _clusters(@in_neighbors).size; end
  def out_cluster_span; _clusters(@out_neighbors).size; end
end
