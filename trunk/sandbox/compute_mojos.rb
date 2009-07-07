#!/usr/bin/env ruby
require 'igraph'
require 'grok'
require 'mojo'

f_input = ARGV[0] || '/home/rodrigo/svn/swasr/src/downloader/by-size/182-pjirc/numbers.mod'
f_merges = ARGV[1] || '/home/rodrigo/svn/swasr/src/downloader/by-size/182-pjirc/merges_fast'

mod = read_pairs(f_input)
merges = read_pairs(f_merges).map { |x| [x[0].to_f, x[1].to_f] }
merges = IGraphMatrix.new(*merges)
g = IGraph::Generate.tree(mod.size, 2, IGraph::TREE_UNDIRECTED)

merges.nrow.times do |i|
  clustering = g.community_to_membership(merges, i + 1, g.vcount)
  #p clustering
  f = Tempfile.new('temp')
  clustering.each_with_index do |cluster, id|
    cluster.each { |element| f.puts "#{element} #{id}"}
  end
  f.close
  #puts "#{f_input} #{f.path}"
  puts "#{mojosim(f.path, f_input)} #{g.modularity(clustering)}"
  f.delete
  #STDIN.gets
end


