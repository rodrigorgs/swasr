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
  STDERR.puts "Reading modules..."
  network.set_clusters(read_pairs(c.modules_file))
  STDERR.puts "Sorting nodes according to modules..."
  
  n = network.nodes.size
  sorted_nodes = network.nodes.group_by{ |node| node.cluster }.values.flatten
  sorted_nodes.each_with_index { |node, i| node.id = i }

  STDERR.puts "Creating image..."

  image = GD2::Image::TrueColor.new(n, n)
  image.draw do |canvas|
    canvas.color = GD2::Color::WHITE
    canvas.fill
    canvas.color = GD2::Color::BLACK
    network.edges.each do |e|
      canvas.circle(e.from.id, e.to.id, c.size, true)
    end
  end
  image.export(c.png_file)

  STDERR.puts "Ok"
end
