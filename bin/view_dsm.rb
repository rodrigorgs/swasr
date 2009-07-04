#!/usr/bin/env ruby

if __FILE__ == $0

  require 'view_matrix'
  require 'grok'
  require 'network'
  require 'matrix_to_png'
  require 'choice'

  Choice.options do
    header ''
    header 'One of -b, -e is required'
    header ''

    option :basename do
      short '-b'
      desc 'Base file name. We\'ll look for files'
      desc 'named XXX.arc and XXX.mod, where XXX'
      desc 'is the base file name.'
    end
    
    option :edges_file  do
      short '-e'
      long '--edges=FILE'
      desc 'File in PAIRS edges format'
    end

    option :modules_file do
      short '-m'
      long '--modules=FILE'
      desc 'File in PAIRS modules format'
    end

    option :png_file do
      short '-o'
      long '--output=FILE.png'
      default 'dsm.png'
      desc 'Output image file'
      desc '(default: dsm.png)'
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
  if !c.basename.nil?
    p 'entrei'
    c.basename = c.basename[0..-2] if c.basename[-1..-1] == '.'
    c.edges_file = c.basename + '.arc'
    c.modules_file = c.basename + '.mod'
  end

  if c.edges_file.nil?
    Choice.help
    exit 1
  end

  clusters = nil
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
    sorted_nodes = clusters.map{ |cluster| cluster.sort_by(&:eid)}.flatten
  else
    sorted_nodes = network.nodes
  end

  STDERR.puts "Creating image file #{c.png_file}..."

  n = sorted_nodes.size
  sorted_nodes.each_with_index { |node, i| node.data.pos = i }
  image = GD2::Image::TrueColor.new(n, n)
  image.draw do |canvas|
    canvas.color = GD2::Color::WHITE
    canvas.fill

    if clusters
      i = 0
      canvas.color = GD2::Color[1.0, 1.0, 0]
      clusters.map { |clust| clust.size }.each do |w|
        canvas.rectangle(i, i, i + w -1, i + w -1, true)
        i += w
      end
    end

    canvas.color = GD2::Color::BLACK
    network.edges.each do |e|
      canvas.circle(e.from.data.pos, e.to.data.pos, c.psize, true)
    end
  end
  image.export(c.png_file)

  STDERR.puts "Ok"
end
