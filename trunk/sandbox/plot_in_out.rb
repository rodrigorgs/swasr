#!/usr/bin/env ruby

require 'grok'

# Returns a hash: node_id => [out_degree, in_degree]
def node_degrees(pairs)
  hash = Hash.new
  pairs.each do |x, y|
    hash[x] ||= [0, 0]
    hash[y] ||= [0, 0]
    hash[x][0] += 1
    hash[y][1] += 1
  end
  return hash
end

# List of [out_degree, in_degree] pairs (one pair for each node)
def out_in_degrees(pairs)
  node_degrees(pairs).values
end

