#!/usr/bin/env ruby
require 'igraph'
require 'grok'
require 'mojo'

def get_base_mojo(f_input)
  input_mod = read_pairs(f_input)
  giant_mod = input_mod.map { |a, _| [a, 0] }
  
  f = Tempfile.new('cpt')
  giant_mod.each { |a, b| f.puts "#{a} #{b}" }
  f.close(false)
  base_mojo = mojosim(f.path, f_input)
  f.unlink
  return base_mojo
end

def compute_miojo(mjsim, base_mojo)
  miojo = if (mjsim >= base_mojo) then
    (mjsim - base_mojo) / (1 - base_mojo).to_f
  else
    (mjsim - base_mojo) / (base_mojo).to_f
  end
 end

def compute_mojos(f_input, f_merges, output=nil)
  mod = read_pairs(f_input)
  merges = read_pairs(f_merges).map { |x| [x[0].to_f, x[1].to_f] }
  merges = IGraphMatrix.new(*merges)

  g = IGraph::Generate.tree(mod.size, 2, IGraph::TREE_UNDIRECTED)

  base_mojo = get_base_mojo(f_input)
  puts "base_mojo: #{base_mojo}"

  ret = []
  merges.nrow.times do |i|
    clustering = g.community_to_membership(merges, i + 1, g.vcount)

    f = Tempfile.new('cpt')
    clustering.each_with_index do |cluster, id|
      cluster.each { |element| f.puts "#{element} #{id}"}
    end
    f.close

    mjsim = mojosim(f.path, f_input)
    miojo = compute_miojo(mjsim, base_mojo)
    modules = merges.nrow - (i + 1)
    modularity = g.modularity(clustering)

    x = [mjsim, miojo, modularity, modules]
    p x
    ret << x
    f.unlink
  end

  if output
    File.open(output, 'w') do |f|
      f.puts("mojosim miojo modularity modules")
      ret.each { |e| f.puts e.join(" ") }
    end
  end

  return ret
end

#f_input = ARGV[0] || '/home/rodrigo/svn/swasr/src/downloader/by-size/182-pjirc/numbers.mod'
#f_merges = ARGV[1] || '/home/rodrigo/svn/swasr/src/downloader/by-size/182-pjirc/merges_fast'

compute_mojos *ARGV if __FILE__ == $0
#(f_input, f_merges, '/tmp/bli')

#mod = read_pairs(f_input)
#merges = read_pairs(f_merges).map { |x| [x[0].to_f, x[1].to_f] }
#merges = IGraphMatrix.new(*merges)
#g = IGraph::Generate.tree(mod.size, 2, IGraph::TREE_UNDIRECTED)
#
#merges.nrow.times do |i|
#  clustering = g.community_to_membership(merges, i + 1, g.vcount)
#  #p clustering
#  f = Tempfile.new('temp')
#  clustering.each_with_index do |cluster, id|
#    cluster.each { |element| f.puts "#{element} #{id}"}
#  end
#  f.close
#  #puts "#{f_input} #{f.path}"
#  puts "#{mojosim(f.path, f_input)} #{g.modularity(clustering)}"
#  f.delete
#  #STDIN.gets
#end


