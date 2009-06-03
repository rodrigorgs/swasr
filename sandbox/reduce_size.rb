#!/usr/bin/env ruby

require 'network'
require 'fileutils'

include FileUtils

_size = ARGV[0].to_i

net = Network.new
net.load2 'numbers'

net.reduce_size _size

mkdir 'reduced' unless File.exist? 'reduced'
net.save2('reduced/numbers')
