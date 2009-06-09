#!/usr/bin/env ruby
require 'gxl'

# Shows vertices that aren't inside any module

farc = ARGV[0] || 'names.arc'
fmod = ARGV[1] || 'names.mod'

arc_nodes = entities(read_pairs(farc))
mod_nodes = read_pairs(fmod).map { |x,_| x }

puts (arc_nodes - mod_nodes).sort
