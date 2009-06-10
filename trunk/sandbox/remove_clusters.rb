#!/usr/bin/env ruby

require 'network'

if ARGV.size < 3
  puts "Parameters: input-network output-network cluster-names+"
  puts
  exit 1
end

n = Network.new
n.load2(ARGV[0])

ARGV[2..-1].each do |c|
  n.remove_cluster(c)
end

n.save2(ARGV[1])
