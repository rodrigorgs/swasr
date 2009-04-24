#!/usr/bin/env ruby

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
      default 4
      desc 'Pixel diameter (default: 4)'
    end
  end

  c = Choice.choices

  network = Network.new
  STDERR.puts "Reading edges..."
  network.add_edges(read_pairs(c.edges_file))
  if (c.modules_file)
    STDERR.puts "Reading modules..."
    network.set_clusters(read_pairs(c.modules_file))
    STDERR.puts "Sorting nodes according to modules..."
  
    # Ordena os clusters por tamanho. Dentro de cada cluster, os vertices
    # sao ordenados de acordo com o id
    clusters = network.nodes.group_by(&:cluster).values.sort_by(&:size)
    sorted_nodes = clusters.map{ |cluster| cluster.sort_by(&:id)}.flatten
  else
    sorted_nodes = network.nodes
  end

  STDERR.puts "Creating image..."

  n = sorted_nodes.size
  sorted_nodes.each_with_index { |node, i| node.id = i }
  image = GD2::Image::TrueColor.new(n, n)
  image.draw do |canvas|
    canvas.color = GD2::Color::WHITE
    canvas.fill
    canvas.color = GD2::Color::BLACK
    network.edges.each do |e|
      canvas.circle(e.from.id, e.to.id, c.psize, true)
    end
  end
  image.export(c.png_file)

  STDERR.puts "Ok"
end
