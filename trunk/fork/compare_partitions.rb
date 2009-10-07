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
  value = `java mojo.MoJo #{a} #{b} 2> /dev/null`
  #LOG.info(value)
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

def entropy(clustering)
  n = clustering.flatten.size
  e = 0.0
  clustering.each do |cluster|
    x = cluster.size.to_f / n
    e += x * Math.log(x)
  end
  return -e
end

def mutual_information(found, reference)
  nelems = [found.flatten.size, reference.flatten.size].max

  total = 0.0
  found.each do |wk|
  reference.each do |cj|
    common = (wk & cj).size
    if common != 0  # 0 * log(0) == 0
      x = (common.to_f / nelems)
      y = Math.log((nelems * common).to_f / (wk.size * cj.size))
      total += x * y
    end
  end
  end

  return total
end

# Normalized mutual information
# http://nlp.stanford.edu/IR-book/html/htmledition/evaluation-of-clustering-1.html
def nmi(found, reference)
  a = load_clusters(found)
  b = load_clusters(reference)

  mi = mutual_information(a, b).to_f
  ent = ((entropy(a) + entropy(b)) / 2.0)

  return (ent == 0.0) ? (1.0) : (mi / ent)
end

def tests
  methods = %w(mojosim purity nmi)
  hash = {
      :singletons => "0 0\n1 1\n2 2\n3 3\n4 4",
      :black_hole => "0 0\n1 0\n2 0\n3 0\n4 0",
      :half1 => "0 0\n1 0\n2 0\n3 1\n4 1",
      :half2 => "0 0\n1 0\n2 1\n3 1\n4 1"
  }
 
  hash.keys.each do |x1|
  hash.keys.each do |x2|
  puts "== #{x1} --> #{x2} =="
  methods.each do |m|
    puts "#{m} #{send(m, StringIO.new(hash[x1]), StringIO.new(hash[x2]))}"
  end
  puts
  end
  end
end

tests if __FILE__ == $0
