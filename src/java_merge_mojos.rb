#!/usr/bin/env jruby

require 'java'
require 'grok'
require 'merge'

import 'mojo.MoJoCalculator'

def compute_mojos(f_input, f_merges, output=nil)
  target = read_pairs(f_input).flatten.to_java(:string)
  merges = read_pairs(f_merges).map { |a, b| [a.to_i, b.to_i] }
  n = target.size / 2

  out = nil
  out = File.open(output, 'w') if output

  do_merges(merges, n) do |s|
    source = groups_to_pairs(s).map { |x| x.to_s }.to_java(:string)
    value = MoJoCalculator.new("", "", "").mojo(source, target)
    puts value
    out.puts value if out
  end

  out.close if out
end

if __FILE__ == $0
  compute_mojos *ARGV
end

# MY_ARRAY.to_java(Java::double[])
