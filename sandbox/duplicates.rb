#!/usr/bin/env ruby
# Detects nodes that belong to more than one module

require 'grok'

modules_file = ARGV[0] || 'names.mod'

pairs = read_pairs(modules_file)
groups = pairs.group_by { |node, mod| node }.select { |k, v| v.size > 1 }.map { |k, v| [k, v.map { |a, b| b }] }

mods = Hash.new(0)

groups.each do |k, mod|
  mod.each do |m|
    mods[m] += 1
  end
end

if !groups.empty?
  puts "== Number of duplicated nodes per module =="
  mods.sort_by { |_, count| count }.reverse.each { |a, b| puts "#{a} #{b}" }
  puts

  puts "== Intersecting modules =="
  groups.map { |_, x| x }.uniq.each { |x| p x }
  puts

  puts "== Repeated nodes and corresponding modules =="
  groups.each { |node, mod| puts "#{node} #{mod.inspect}" }
  puts
end 
