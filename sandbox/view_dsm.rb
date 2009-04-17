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

    option :size do
      short '-s'
      long '--size=N'
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

  array = sort_network!(net)
  STDERR.puts "Creating image..."
  matrix_to_png(array, c.png_file, c.size)
  STDERR.puts "Ok"
end
