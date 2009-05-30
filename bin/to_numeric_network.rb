#!/usr/bin/env ruby

require 'network'

if __FILE__ == $0
  def help_to_numeric
    puts "
    Usage: #{File.basename $0} in-arcs in-modules out-arcs out-modules
    OR
    #{File.basename $0} in-basename out-basename

    Outputs the network relabelled with numbers starting with 0
  " 
    exit 1
  end

  if ARGV.size == 2
    files = [ARGV[0] + '.arc', ARGV[0] + '.mod', ARGV[1] + '.arc' + ARGV[1] + '.mod']
  elsif ARGV.size == 4
    files = ARGV
  else
    help_to_numeric
  end

  net = Network.new
  net.load(files[0], files[1] )

  net.nodes.each_with_index { |n, idx| n.data.i = idx }
  net.clusters.each_with_index { |c, idx| c.data.i = idx }
  net.save(files[2], files[3], :i)
end
