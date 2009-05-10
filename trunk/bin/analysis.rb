#!/usr/bin/env ruby

require 'network'
require 'grok'
require 'choice'

Choice.options do
  header ''
  header 'INPUT'
  option :edges_file do
    short '-e'
    long '--edges=FILE'
    default 'l1.pairs'
    desc 'File in PAIRS edges format'
    desc '(default: l1.pairs)'
  end
 
  option :modules_file do
    short '-m'
    long '--modules=FILE'
    default 'modules.pairs'
    desc 'File in PAIRS modules format'
    desc '(default: modules.pairs)'
  end

  separator ''
  separator 'PROCESSING'

#  option :undirected do
#    short '-u'
#    desc 'Threat the network as undirected'
#  end

  separator ''
  separator 'OUTPUT'
  option :file_vertices do
    short '-v'
    default 'vertices.data'
    desc 'Output filename for vertice metrics'
    desc '(default: vertices.data)'
  end

  option :file_clusters do
    short '-c'
    default 'clusters.data'
    desc 'Output filename for module metrics'
    desc '(default: clusters.data)'
  end

  option :file_global do
    short '-g'
    default 'global.data'
    desc 'Output filename for global metrics'
    desc '(default: global.data)'
  end
  
  separator ''
end

c = Choice.choices

if not File.file?(c.edges_file)
  Choice.help
  exit 1
end
if not File.file?(c.modules_file)
  puts "Warning: File #{c.modules_file} does not exist."
  c.modules_file = nil
end
network = Network.new(c.edges_file, c.modules_file)

# VERTICES analysis
File.open(c.file_vertices, "w") do |f|
  f.puts "eid deg indeg outdeg nclusters ext_indeg int_indeg ext_outdeg int_outdeg clust_coef"
  network.nodes.each do |n|
    f.puts "#{n.eid} #{n.degree} #{n.in_degree} #{n.out_degree}" +
        " #{n.cluster_span} #{n.external_in_degree} #{n.internal_in_degree}" +
        " #{n.external_out_degree} #{n.internal_out_degree}" +
        " #{network.clustering_coefficient(n)}"
  end
end

# TODO: motif analysis. UPDATE: parece que o igraph faz isso!

# CLUSTER analysis
File.open(c.file_clusters, "w") do |f|
  f.puts "eid size"
  network.clusters.each do |cluster|
    f.puts "#{cluster.eid} #{cluster.size}"
  end
end

# GLOBAL analysis
File.open(c.file_global, "w") do |f|
#  density = network.edges.size.to_f / network.size
  edges_un = network.edges_undirected
  extra_edges_un = edges_un.select { |e| e.from.cluster != e.to.cluster }

  #sum_mixing = network.nodes.inject(0.0) do |sum, node|
  #  sum + (node.degree == 0 ? 0 : node.external_degree.to_f / node.degree)
  #end
  #mixing = sum_mixing.to_f / network.size
  mixing = extra_edges_un.size.to_f / edges_un.size

  f.puts "nodes edges edges_un clusters extra_edges_un mixing"
  f.puts "#{network.size}" +
      " #{network.edges.size}" +
      " #{network.edges_undirected.size}" +
      " #{network.clusters.size}" + 
      " #{extra_edges_un.size}" +
      " #{mixing}"
end

# architecture
g = network.lift
g.nodes.each { |n| g.edge!(n, n) }
puts_pairs g.edges.map { |e| [e.from.eid, e.to.eid] }, 'l2.pairs'
