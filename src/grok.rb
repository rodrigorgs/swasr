#!/usr/bin/env ruby
# Operations with arrays and tabular files

def read_rsf_pairs(filename=nil, relations=[])
	relations = [relations] if !relations.kind_of?(Array)

	pairs = []
  if filename.nil?
    lines = STDIN.readlines
  else
  	lines = IO.readlines(filename)
  end
	lines.map{ |line| line.strip.split(/\s+/) }.each do |rel, e1, e2|
		pairs << [e1, e2] if relations.empty? || relations.include?(rel)
	end

	return pairs
end

def read_pairs(filename=nil)
  lines = (if filename.nil?
    STDIN.readlines
  elsif filename.kind_of?(String) 
    IO.readlines(filename)
  elsif filename.kind_of?(IO)
    filename.readlines
  else
    raise Exception("Unsupported filename parameter type.")
  end)
    
  pairs = lines.map{ |line| line.strip.split(/\s+/) }
  return pairs
end

def puts_pairs(pairs, filename=nil)
  if filename.nil?
    pairs.each { |x, y| puts "#{x} #{y}" }
  else
    File.open(filename, 'w') { |f| pairs.each { |x, y| f.puts "#{x} #{y}" } }
  end
end

def entities(pairs)
  pairs.flatten.uniq
end

def grep(pairs, regex1, regex2=/.*/)
  pairs.select { |x, y| x =~ regex1 && y =~ regex2 }
end

# adjacency list:
# The nth-row contains the indices of nodes that are adjacent to the nth-node
# (zero-based). 
# Note that the pair's elements  must be sequential numbers starting from 0.
#
# adjacency list:
#
#  [
#   [1, 2, 3],
#   [2],
#   [],
#   [1, 2]
#  ]
#
# is equivalent to:
#  [
#   [0, 1], [0, 2], [0,3],
#   [1, 2],
#   [3, 2]
#  ]
#   
def numbered_pairs_to_adjacency_list(pairs, directed=false)
  nodes = entities(pairs).sort
  n = nodes[-1] + 1
  array = Array.new(n) { Array.new }
  pairs.each do |a, b| 
    array[a] << b
    array[b] << a if !directed
  end
  return array
end

# adjacency matrix: a NxN matrix, where N is the number of nodes
# the element i,j is 1 if there exists a pair [i, j], and 0 otherwise.
#
# Note that the pair's elements  must be sequential numbers starting from 0.
def numbered_pairs_to_adjacency_matrix(pairs, directed=false)
  nodes = entities(pairs).sort
  n = nodes[-1] + 1
  matrix = Array.new(n) { Array.new(n) { 0 } }
  pairs.each do |a, b| 
    matrix[a][b] = 1
    matrix[b][a] = 1 if !directed
  end
  return matrix
end

class Array
  def unzip
    max = self.map{ |a| a.size }.max
    return [] if max.nil?
    ret = []
    max.times { ret << [] }
    self.each do |a|
      0.upto(max - 1) { |i| ret[i] << a[i] }
    end
    return ret
  end
end

# returns a hash relation_name => pair
#def getdb(filename=nil)
#  file = filename.nil? && STDIN || File.open(filename, 'r')
#
#  ret = {}
#  file.each_line do |line|
#    line = line.strip
#    next if line.size == 0 || line[0] == '#'
#    triple = line.split(/\s+/)
#    relation, pair = triple[0], triple[1..2]
#    hash[pair] ||= []
#    hash[pair] << pair
#  end
#
#  file.close unless file == STDIN
#  return ret
#end
