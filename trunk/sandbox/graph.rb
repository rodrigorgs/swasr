require 'rgl/adjacency'
require 'rgl/connected_components'

def pairs_to_graph(pairs)
  RGL::DirectedAdjacencyGraph[*(pairs.flatten)]
end

def n_strongly_connected_components(graph)
  graph.strongly_connected_components.num_comp
end
