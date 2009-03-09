#!/usr/bin/env ruby

require 'rgl/adjacency'
require 'rgl/dot'
require 'rgl/connected_components'
require 'rgl/topsort'

# class*_cgraph.dot
# class*__coll__graph.dot
# class*__inherit_graph.dot
#
# The DOT files used as input are generated by Doxygen
module Extractor
  NODE_REGEX = /^\s*Node(\d+) \[.*label="(.+?)"/
  EDGE_REGEX = /^\s*Node(\d+) -> Node(\d+) \[.*style="(.+?)"/

  def Extractor.extract(dir="./")
    dg = RGL::DirectedAdjacencyGraph.new

    Dir.glob("#{dir}class*.dot") do |filename|
      node_labels = []

      # nodes
      IO.foreach(filename) do |line|
        if line =~ NODE_REGEX then 
          id, label = $1.to_i, $2
          class_name = label.split("::")[0..-2].join("::")
          node_labels[id.to_i] = class_name
          dg.add_vertex(class_name)
        end
      end

      # edges
      IO.foreach(filename) do |line|
        if line =~ EDGE_REGEX 
          i1, i2 = $1.to_i, $2.to_i
          dg.add_edge(node_labels[i1], node_labels[i2]) unless i1 == i2
        end
      end
    end

    return dg
  end
end

# = Ideia
#
# Usa como entrada o grafo nao-orientado
#
# O processo consiste em remover alguns vertices de maneira que o numero
# de componentes conexas (CC) aumente, evitando CCs muito pequenas. Pode-se
# usar para isso um algoritmo monte carlo.
#
# Pode-se usar a heuristica de remover vertices com maior grau
module Clusterer
end

module Info
  def Info.num_components(graph)
    i = 0
    graph.each_connected_component { |cc| i+= 1 }
    return i  
  end

  def Info.stats(graph)
    puts "Nodes: #{graph.num_vertices}"
    puts "Edges: #{graph.num_edges}"
    puts "CC   : #{num_components(graph)}"
    puts
  end

  def Info.show_components(graph)
    graph.each_connected_component do |cc|
      puts cc.join("\n")
      puts "-----------------------------"
    end
  end
end

if __FILE__ == $0
  dg = Extractor::extract
  ug = dg.to_undirected

  Info::stats(ug)

  [ug, dg].each do |graph|
    graph.remove_vertex("InGE::Vector2")
    graph.remove_vertex("InGE::Vector3")
    graph.remove_vertex("InGE::Vector4")
    graph.remove_vertex("InGE::IEntity")
  end

  iter = dg.topsort_iterator

  Info::stats(ug)

  Info::show_components(ug)

  #dg.write_to_graphic_file
end
