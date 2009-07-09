#!/usr/bin/env ruby
require 'tempfile'
require 'fileutils'

def pairs_to_rsf(pairs, rsf)
  File.open(rsf, 'w') do |g|
  File.open(pairs, 'r') do |f|
    f.each_line { |l| g.puts "contain #{l.split.reverse.join(' ')}" }
  end
  end
end

def mojo(file1, file2)
  f = Tempfile.new('mojo')
  g = Tempfile.new('mojo')
  a = f.path
  b = g.path
  f.close(true)
  g.close(true)

  pairs_to_rsf file1, a
  pairs_to_rsf file2, b
  value = `java mojo.MoJo #{a} #{b}`.to_i
  FileUtils.rm [a, b]
  return value
end

def mojosim(file1, file2)
  n = IO.readlines(file1).size  
  m = mojo(file1, file2)
  return 1 - (m.to_f / n)
end

if __FILE__ == $0
  puts mojosim ARGV[0], ARGV[1]
end
