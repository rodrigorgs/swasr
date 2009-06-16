#!/usr/bin/env ruby

require 'grok'

input = ARGV[0]
output = ARGV[1]

pairs = read_pairs(input)

pairs.map! { |p| p.map { |x| x.to_i } }
max = entities(pairs).max + 1
pairs.map! { |p| p.map { |x| x == 0 ? max : x } }
pairs = pairs.select { |a, b| a != b }

File.open(output, 'w') do |f|
  pairs.each { |p| f.puts "#{p[0]} #{p[1]} 1" }
end
