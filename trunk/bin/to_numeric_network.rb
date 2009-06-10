#!/usr/bin/env ruby

require 'network'

def index_network(net)
  net.nodes.each_with_index { |n, idx| n.data.i = idx }
  net.clusters.each_with_index { |c, idx| c.data.i = idx }
  true
end

def to_numeric_network(iarc, imod, oarc, omod)
  net = Network.new
  net.load(iarc, imod)

  net.nodes.each_with_index { |n, idx| n.data.i = idx }
  net.clusters.each_with_index { |c, idx| c.data.i = idx }
  net.save(oarc, omod, :i)
end

def to_numeric_network_base(input, output)
  to_numeric_network(input + '.arc', input + '.mod', output + '.arc', output + '.mod')
end

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
    to_numeric_network_base(*ARGV)
  elsif ARGV.size == 4
    to_numeric_network(*ARGV)
  else
    help_to_numeric
  end

end
