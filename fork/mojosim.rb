#!/usr/bin/env ruby
require 'tempfile'
require 'fileutils'

# pairs : IO
# rsf : String (filename)
def pairs_to_rsf(pairs, rsf)
  File.open(rsf, 'w') do |g|
    pairs.each_line { |l| g.puts "contain #{l.split.reverse.join(' ')}" }
  end
end

# file1 : IO
# file2 : IO
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
  m = mojo(file1, file2)
  file1.rewind
  n = file1.readlines.size
  return 1 - (m.to_f / n)
end

#if __FILE__ == $0
#  puts mojosim ARGV[0], ARGV[1]
#end
