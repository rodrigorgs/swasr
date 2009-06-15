#!/usr/bin/env ruby

require 'grok'

input = ARGV[0]
output = ARGV[1]

pairs = read_pairs(input)

pairs.map! { |p| p.map { |x| x.to_i } }
max = entities(pairs).max + 1
pairs.map! { |p| p.map { |x| x == 0 ? max : x } }

puts_pairs(pairs, output)
