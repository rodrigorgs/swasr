#!/usr/bin/env ruby

# Takes a Network and returns an adjacency matrix, represented as an array of
# arrays. The lines and columns in the matrix are sorted so vertices that
# belong in the same cluster appear as adjacent rows/columns.
def network_to_sorted_array(network)
  n = network.nodes.size
  sorted_nodes = network.nodes.group_by{ |node| node.cluster }.values.flatten
  sorted_nodes.each_with_index { |node, i| node.id = i }
  array = Array.new(n) { Array.new(n) { 0 } }
  network.edges.each { |e| array[e.from.id][e.to.id] = 1 }

  return array
end

if __FILE__ == $0

  require 'view_matrix'
  require 'grok'
  require 'network'
  require 'matrix_to_png'
  require 'choice'

  Choice.options do
    option :edges_file, :required => true do
      short '-e'
      long '--edges=FILE'
      desc 'File in PAIRS edges format'
      desc '(required)'
    end

    option :modules_file do
      short '-m'
      long '--modules=FILE'
      desc 'File in PAIRS modules format'
    end

    option :png_file do
      short '-o'
      long '--output=FILE.png'
      desc 'Output image file'
    end

    option :psize do
      short '-s'
      long '--size=N'
      cast Integer
      default 1
      desc 'Pixel size (default: 1)'
    end
  end

  c = Choice.choices

  net = Network.new
  STDERR.puts "Reading edges..."
  net.add_edges(read_pairs(c.edges_file))
  if c.modules_file
    STDERR.puts "Reading modules..."
    net.set_clusters(read_pairs(c.modules_file))
    STDERR.puts "Sorting nodes according to modules..."
  else
    STDERR.puts "Creating matrix..."
  end

  array = network_to_sorted_array(net)
  STDERR.puts "Creating image..."
  matrix_to_png(array, c.png_file, c.psize)
  STDERR.puts "Ok"
end
