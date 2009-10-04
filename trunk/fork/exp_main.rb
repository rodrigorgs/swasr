#!/usr/bin/env ruby

require 'exp_clust'

def import_sw_networks
  exp = ClusteringExperiment.new
  base = '/home/rodrigo/dataset/01-java'
  Dir.foreach(base) do |dir|
    next if dir[0] == '.'
    puts dir
    arc = IO.read("#{base}/#{dir}/numbers.arc")
    mod = IO.read("#{base}/#{dir}/numbers.mod")
    name = dir
    classification = ClusteringExperiment::CLASS_SOFTWARE
    exp.insert_natural_network name, arc, mod, classification
  end
end

def import_architectures
  exp = ClusteringExperiment.new
  exp.db[:architecture].delete
  base = '/home/rodrigo/bcr2/architectures'
  i = 1
  Dir.foreach(base).sort.each do |dir|
    next if dir[0] == '.'
    puts dir
    arc = IO.read("#{base}/#{dir}/arch-numbers.arc")
    mod = IO.read("#{base}/#{dir}/arch-numbers.mod")
    name = dir
    exp.insert_safe :architecture,
      :pk_architecture => i,
      :nme_architecture => name,
      :arc_architecture => arc,
      :mod_architecture => mod
    i += 1
  end
end

if __FILE__ == $0
  import_sw_networks
  import_architectures
end

