#!/usr/bin/env ruby
# Converts pairs of strings to pairs of numbers starting from 0

require 'grok'

names = read_pairs(ARGV[0])
numbers = []

hash = {}

next_index = 0
names.each do |pair|
  numerized = pair.map do |name|
    number = hash[name]
    if !number
      number = next_index
      hash[name] = next_index
      next_index += 1
    end
    number
  end
  numbers << numerized
end


puts_pairs(numbers)
