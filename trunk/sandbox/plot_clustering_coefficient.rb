#!/usr/bin/env ruby

require 'grok'

def compute_node_degrees(pairs)
  hash = Hash.new #([0, 0]) # [out, in]
  pairs.each do |x, y|
    hash[x] ||= [0, 0]
    hash[y] ||= [0, 0]
    hash[x][0] += 1
    hash[y][1] += 1
  end
  return hash
end

# undirected
def node_clustering_coefficients(pairs)
  STDERR.puts pairs.size
  # remove duplicate pairs -- note that [a, b] == [b, a]
  pairs = pairs.map{ |pair| pair.sort }.uniq
  STDERR.puts pairs.size
  hash = {}
  entities(pairs).each do |e|
    entity_pairs = pairs.select { |pair| pair.include? e }
    neighbors = entities(entity_pairs) - [e]
    neighbors_pairs = pairs.select{ |pair| (pair & neighbors).size == 2 }
    
    n = neighbors_pairs.size # number of linked neighbors
    k = entity_pairs.size # degree
    c_k = (2 * n).to_f / (k * (k - 1))
    hash[e] = [k, c_k] unless c_k.nan?
  end
  return hash
end

def clustering_coefficients(pairs)
  return node_clustering_coefficients(pairs).values.sort_by { |k, c_k| k }
end
