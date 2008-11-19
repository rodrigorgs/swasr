#!/usr/bin/env ruby

require 'rsruby'
require 'grok'
require 'graph_metrics'

class Array
  def unzip
    max = self.map{ |a| a.size }.max
    ret = []
    max.times { ret << [] }
    self.each do |a|
      0.upto(max - 1) { |i| ret[i] << a[i] }
    end
    return ret
  end
end

def pairs_log(pairs)
  return pairs.select{ |x, y| x != 0 && y != 0}.
      map {|x, y| [Math.log(x), Math.log(y)] }.
      select { |a| a[0].finite? && a[1].finite? }
end

def lmfit(x, y)
  r = RSRuby.instance
  r.assign('xs', x)
  r.assign('ys', y)
  model = r.eval_R('ys ~ xs')
  old_mode = RSRuby::get_default_mode
  RSRuby::set_default_mode(RSRuby::NO_CONVERSION)
  fit = r.lm(model)
  RSRuby::set_default_mode(RSRuby::BASIC_CONVERSION)

  r2 = r.summary(fit)['r.squared']
  a = fit.to_ruby['coefficients']['(Intercept)']
  b = fit.to_ruby['coefficients']['xs']
  
  return {:a => a, :b => b, :r2 => r2}
  
  #Alternative (without r2)
  #fit = r.lsfit(d[0], d[1])
  #r.abline(:b => fit['coefficients']['X'], :a => fit['coefficients']['Intercept'], :col => 'red')
end

if __FILE__ == $0
  filename = ARGV[0]
  if filename.nil?
    puts "Usage: #{File.basename($0)} filename

    "
    exit 1
  end

  pairs = read_rsf_pairs(filename)

  cc = clustering_coefficients(pairs)
  ds = out_in_degrees(pairs)
  din = cumulative_in_degrees(pairs)
  dout = cumulative_out_degrees(pairs)
 
  r = RSRuby.instance

  # degree dist
  d = pairs_log(din).unzip
  r.png("teste.png")
  r.plot('x' => d[0], 'y' => d[1], 
      'main' => 'Degree distribution',
      'xlab' => 'k (log)',
      'ylab' => 'number of vertices with degree >= k (log)',
      'pch' => 21, :bg => 'red')
  
  fit = lmfit(d[0], d[1])
  r.abline(fit[:a], fit[:b], :col => 'red', :lty => 2)
 
  d = pairs_log(dout).unzip
  r.points(d[0], d[1], :pch => 23, :bg => 'blue')
  
  fit = lmfit(d[0], d[1])
  r.abline(fit[:a], fit[:b], :col => 'blue', :lty => 2)

  r.dev_off.call
  sleep(2)
end
