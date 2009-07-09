#!/usr/bin/env ruby

# implementation of
# http://igraph.sourceforge.net/doc/html/igraph_community_to_membership.html
def do_merges(merges, n, &block)
  # index: cluster id. value: elements in the cluster
  clusters = Array.new(2*n) { |i| i < n ? [i] : nil }
  next_id = n

  merges.each do |a, b|
    new = clusters[a] + clusters[b]
    clusters[a] = nil
    clusters[b] = nil
    clusters[next_id] = new
    next_id += 1

    block.call clusters.compact if block
  end
  return clusters.compact
end

# groups_to_pairs [[0,1], [2,3]] ==> [0,0, 1,0, 2,1, 3,1]
def groups_to_pairs(groups)
  pairs = []
  id = 0
  groups.each do |group|
    if !group.nil?
      group.each { |e| pairs += [e, id] }
      id += 1
    end
  end
  return pairs
end

p groups_to_pairs([nil, [1,2], nil, [3,4]]) if __FILE__ == $0
