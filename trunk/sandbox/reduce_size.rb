#!/usr/bin/env ruby

require 'network'
require 'fileutils'
require 'to_numeric_network'

include FileUtils

if ARGV.size < 3
  puts "Parameters: input-network output-network size"
  puts
  exit 1
end

_size = ARGV[2].to_i

net = Network.new
net.load2(ARGV[0])

net.reduce_size _size

#index_network(net)
net.save2(ARGV[1], :i)

