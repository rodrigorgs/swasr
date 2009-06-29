#!/usr/bin/env ruby

def readfile(name)
  return IO.readlines(name).map { |l| l.to_f }
end

ARGV.each do |arg|
  puts readfile(arg).join(",")
end
