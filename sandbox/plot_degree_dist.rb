#!/usr/bin/env ruby

require 'grok'

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

# -------------------------------------------------

#def plot_degree_vs_node_count(filename, relations)
#	pairs = read_rsf_pairs(filename, relations)
#
#	degrees = compute_degrees(pairs)
#	data = {}
#	data['in'] = cumulative_degree_vs_node_count(degrees['in']).to_a
#	data['out'] = cumulative_degree_vs_node_count(degrees['out']).to_a
#  
#  data.each_pair do |k, curve|
#    curve.sort.each { |x, y| puts "#{x} #{y}" }
#    puts
#  end
#end
#
#if __FILE__ == $0
#  if ARGV.size < 1
#    puts "Usage: #{$0} filename.rsf [relation1 relation2 relation3 ...]"
#    exit 1
#  end
#  plot_degree_vs_node_count(ARGV[0], ARGV[1..-1])
#end
