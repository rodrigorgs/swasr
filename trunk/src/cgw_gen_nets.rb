#!/usr/bin/env ruby

require 'random_graphs'

def read_params(file)
  return IO.readlines(file)[0].chomp.split("\t").map { |x| eval(x) }
end

files = Dir.glob("**/model_params").sort
total = files.size
time_start = Time.now

count = 0
files.each do |file|
  dir = File.dirname(file)
  puts dir
  if !File.exists?("#{dir}/numbers.arc")
    args = read_params(file)
    puts "  #{args.join(",")}"
    g = gu_game(*args)
    g.save2("#{dir}/numbers")
    sleep 5
  else
    total -= 1
  end
  count += 1
  interval = (Time.now - time_start)
  puts interval
  # interval  --  count
  # X         --  total
  remaining = (interval * total) / count # seconds
  puts "Time remaining: #{remaining / 3600.0} hours"
end
