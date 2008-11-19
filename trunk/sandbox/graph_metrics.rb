#!/usr/bin/env ruby

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
  #STDERR.puts pairs.size
  # remove duplicate pairs -- note that [a, b] == [b, a]
  pairs = pairs.map{ |pair| pair.sort }.uniq
  #STDERR.puts pairs.size
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

def compute_degrees(edges)
	out_degrees = Hash.new(0)
	in_degrees = Hash.new(0)
	edges.each do |from, to|
		out_degrees[from] += 1
		in_degrees[to] += 1
	end

	return {'in' => in_degrees, 'out' => out_degrees}
end

# degrees: a hash from node_id to degree
# output: a hash from degree to count
def degree_vs_node_count(degrees)
	node_count = Hash.new(0)
	degrees.each_pair { |id, degree| node_count[degree] += 1 }
	return node_count
end

def cumulative_plot(hash)
	cum_hash = hash.dup
	hash.each_pair do |degree, count|
		0.upto(degree - 1) { |k| cum_hash[k] += 1 }
	end
	return cum_hash
end

# node_count: a hash from degree to count
# output: a hash from degree to count(degree >= k)
def cumulative_degree_vs_node_count(degrees)
	return cumulative_plot(degree_vs_node_count(degrees))
end

def cumulative_degrees(pairs, in_or_out)
  degrees = compute_degrees(pairs)
  cumulative_degree_vs_node_count(degrees[in_or_out]).to_a.sort
end

def cumulative_in_degrees(pairs)
  cumulative_degrees(pairs, 'in')
end

def cumulative_out_degrees(pairs)
  cumulative_degrees(pairs, 'out')
end

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

