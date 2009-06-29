#!/usr/bin/env ruby
# detects if a network is directed, looking for mutual edges (size 2 cycles)

require 'grok'

pairs = read_pairs(ARGV[0]).uniq
non_mutual = pairs.map { |x| x.sort }.uniq

if non_mutual.size < pairs.size
  puts "TRUE"
  exit 0
else
  puts "FALSE"
  exit 1
end
