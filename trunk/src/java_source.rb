#!/usr/bin/env ruby
#
# Outputs Java source code from a network using the following rules:
# * each node is a Java class
# * each edge is a method call
#
# The model used here is overly simple: each class contains one static method,
# and an edge to a class is translated into a call to the corresponding static
# method.
#
# The Java source code is expected to be compilable but not executable, since
# there is no main() method and there may exist cycles in the call graph.
#

require 'fileutils'
include FileUtils

def network_to_java(g, dir)
  def cluster_dir(cluster, dir)
    "#{dir}/c#{cluster}"
  end

  mkdir_p dir unless File.exist? dir
  clusters = g.nodes.map{ |n| n.cluster }.uniq
  clusters.each do |c| 
    d = cluster_dir(c.data.name, dir)
    mkdir d unless File.exist?(d) 
  end
  g.nodes.each do |n|
    filename = "#{cluster_dir(n.cluster.data.name, dir)}/C#{n.data.name}.java"
    File.open(filename, 'w') do |f|
      f.puts <<-EOF
package c#{n.cluster.data.name};

public class C#{n.data.name} {
  public static void m() {}
}
      EOF
    end
  end
  g.edges.group_by{ |e| e.from }.each_pair do |from, edges|
    filename = "#{cluster_dir(from.cluster.data.name, dir)}/C#{from.data.name}.java"
    File.open(filename, 'w') do |f|
      f.puts <<-EOF
package c#{from.cluster.data.name};

public class C#{from.data.name} {
  public static void m() {
      EOF
      edges.each do |edge| 
        f.puts "    c#{edge.to.cluster.data.name}.C#{edge.to.data.name}.m();"
      end
      f.puts "  }\n}"
    end
  end
end

if __FILE__ == $0
  require 'network'
  require 'grok'

  g = Network.new
  g.add_edges read_rsf_pairs('../corpora/jhotdraw/whole/chclasses.rsf')
  g.set_clusters read_pairs('../corpora/jhotdraw/whole/clusters.pairs')
  g.nodes.each do |n| 
    n.data.name = n.id.gsub(/^.+\./, '').gsub(/[^\w]/, 'x') 
  end
  g.clusters.each { |c| c.data.name = c.id.gsub(/jhotdraw\./, '') }
  network_to_java(g, 'teste')
end

