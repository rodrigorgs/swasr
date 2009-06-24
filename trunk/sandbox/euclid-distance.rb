#!/usr/bin/env ruby

def readfile(name)
  return IO.readlines(name).map { |l| l.to_f }
end

x = readfile(ARGV[0])
y = readfile(ARGV[1])

sqrsum = 0
x.each_with_index do |_, i|
  sqrsum += (x[i] - y[i])**2
end

puts Math.sqrt(sqrsum)
