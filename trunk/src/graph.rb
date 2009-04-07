require 'rgl/adjacency'
require 'rgl/connected_components'
require 'rgl/mutable'
require 'rgl/dot'

require 'rgl/adjacency'
require 'igraph'

def pairs_to_graph(pairs)
  RGL::DirectedAdjacencyGraph[*(pairs.flatten)]
end

def n_strongly_connected_components(graph)
  graph.strongly_connected_components.num_comp
end

class Array
  alias_method :add, :<<
end

# TODO: test with edgelist_class in [Set, Array]
class DegreesDAG < RGL::DirectedAdjacencyGraph
  include RGL::MutableGraph

  def initialize(*args)
    super(*args)
    @degree_dict = Hash.new
  end

  def add_vertex(v)
    super(v)
    @degree_dict[v] ||= [0, 0]
  end

  def add_edge(u, v)
    old = num_edges
    super(u, v)
    added = num_edges - old

    if added > 0
      raise Exception, 'More than one edge added' if added != 1
      @degree_dict[u][1] += added
      @degree_dict[v][0] += added
    end
  end

  def remove_vertex(v)
    each_adjacent(v) { |u| @degree_dict[u][0] -= 1 }
    @degree_dict.delete(v)
    @vertice_dict.delete(v)

    @vertice_dict.each_pair do |u, adj|
      if adj.include? v
        old = adj.size
        adj.delete(v)
        removed = adj.size - old
        @degree_dict[u][1] -= removed
      end
    end
  end

  def remove_edge(u, v)
    old = num_edges
    super(u, v)
    removed = old - num_edges

    if removed > 0
      @degree_dict[u][1] -= removed
      @degree_dict[v][0] -= removed
    end
  end

  def in_degree(v)
    @degree_dict[v][0]
  end
  
  def out_degree(v)
    @degree_dict[v][1]
  end
end

class RGL::DirectedAdjacencyGraph
  #def in_degree(v)
  #  i = 0
  #  self.each_edge { |a, b| i += 1 if b == v }
  #  return i
  #end
  def to_rsf(filename)
    File.open(filename, 'w') { |f| self.each_edge { 
        |x, y| f.puts "depends #{x} #{y}" }}
  end
end
