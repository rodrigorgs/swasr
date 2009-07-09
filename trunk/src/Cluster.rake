#!/usr/bin/env ruby

require 'rake'
require 'gxl'
require 'cluster_common'
require 'cluster_fast'
require 'cluster_eb'
require 'igraph'
require 'compute_mojos'

$g = IGraph::FileRead.read_graph_edgelist(File.new('numbers.arc'), 1)  
$gu = IGraph::FileRead.read_graph_edgelist(File.new('numbers.arc'), 1)  
$gu.to_undirected(1)

algorithms = %w{fast eb}
default_tasks = algorithms.map { |x| ["mod-#{x}/best_miojo", "mod-#{x}/best_mojo"] }.flatten

task :default => default_tasks

######################################################################

directory 'mod-fast'
task 'mod-fast/merges' => 'mod-fast' do |t|
  merges, _ = $gu.community_fastgreedy
  save_merges merges, t.name
end

directory 'mod-eb'
task 'mod-eb/merges' => 'mod-eb' do |t|
  merges, _, _, _ = $g.community_edge_betweenness(true)
  save_merges merges, t.name
end

######################################################################
#
rule(%r{mod-(.+)/mojos} => proc { |x| x.sub(/mojos/, 'merges') }) do |t|
  system "java_merge_mojos.rb numbers.mod #{t.source} #{t.name}"
  #compute_mojos('numbers.mod', t.source, t.name)
end

rule(%r{mod-.*/best_miojo} => proc { |x| x.sub(/best_miojo/, 'mojos') }) do |t|
  miojos = IO.readlines(t.source)[1..-1].map { |line| line.strip.split(" ")[1] }
  File.open(t.name, 'w') { |f| f.puts miojos.max }
end

rule(%r{mod-.*/best_mojo} => proc { |x| x.sub(/best_mojo/, 'mojos') }) do |t|
  miojos = IO.readlines(t.source)[1..-1].map { |line| line.strip.split(" ")[0] }
  File.open(t.name, 'w') { |f| f.puts miojos.max }
end

######################################################################

if __FILE__ == $0; system "rake --trace -f #{$0} #{ARGV.join(' ')}"; end
