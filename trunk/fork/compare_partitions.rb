#!/usr/bin/env ruby
require 'tempfile'
require 'fileutils'
require 'network_base'

# pairs : IO
# rsf : String (filename)
def pairs_to_rsf(pairs, rsf)
  File.open(rsf, 'w') do |g|
    pairs.each_line { |l| g.puts "contain #{l.split.reverse.join(' ')}" }
  end
end

# file1 : IO
# file2 : IO
def mojo(file1, file2)
  f = Tempfile.new('mojo')
  g = Tempfile.new('mojo')
  a = f.path
  b = g.path
  f.close(true)
  g.close(true)

  pairs_to_rsf file1, a
  pairs_to_rsf file2, b
  value = `java mojo.MoJo #{a} #{b}`
  LOG.info(value)
  #FileUtils.rm_f [a, b]
  return Integer(value.strip)
end

def mojosim(file1, file2)
  m = mojo(file1, file2)
  file1.rewind
  n = file1.readlines.size
  return 1 - (m.to_f / n)
end

def load_clusters(stringio)
  pairs = int_pairs_from_string(stringio.read)
  group = pairs.group_by { |node, mod| mod }.values
  group.each do |list|
    list.map! { |node, mod| node }
  end
  return group
end

# parameters are IOs
def purity(proposed, reference)
  purity = 0
  node_to_class = Hash[int_pairs_from_string(reference.read)]
  clustering = load_clusters(proposed)
  clustering.each { |cluster| cluster.map! { |n| node_to_class[n] } }
  clustering.each do |cluster|
    n = cluster.size
    correct = cluster.group_by { |clas| clas }.values.map { |x| x.size }.max
    purity += correct
  end

  return purity.to_f / clustering.flatten.size
end

