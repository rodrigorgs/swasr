#!/usr/bin/env ruby

require 'rsruby'
require 'grok'
require 'graph_metrics'
require 'fileutils'

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
 
def degree_distribution(pairs, system_name)
  din = cumulative_in_degrees(pairs)
  dout = cumulative_out_degrees(pairs)
 
  r = RSRuby.instance

  ret = {}
  ret[:dd_graph] = "#{system_name}-dd.png"

  # in-degree
  
  d = pairs_log(din).unzip
  r.png(ret[:dd_graph])
  r.plot('x' => d[0], 'y' => d[1], 
      'main' => "Degree distribution for #{system_name}",
      'xlab' => 'k (log)',
      'ylab' => 'number of vertices with degree >= k (log)',
      'pch' => 21, :bg => 'red')
  
  fit = lmfit(d[0], d[1])
  r.abline(fit[:a], fit[:b], :col => 'red', :lty => 2)

  ret.merge! :gamma_in => fit[:b], :in_r2 => fit[:r2]

  # out-degree

  d = pairs_log(dout).unzip
  r.points(d[0], d[1], :pch => 23, :bg => 'blue')

  fit = lmfit(d[0], d[1])
  r.abline(fit[:a], fit[:b], :col => 'blue', :lty => 2)
  
  ret.merge! :gamma_out => fit[:b], :out_r2 => fit[:r2]

  r.dev_off.call

  return ret
end

def degree_correlation(pairs, system_name)
  d = out_in_degrees(pairs).unzip

  png_filename = "#{system_name}-dc.png"
  r = RSRuby.instance
  r.png(png_filename)

  r.plot(:x => d[0], :y => d[1],
      :main => "Degree correlation for #{system_name}",
      :xlab => 'in-degree',
      :ylab => 'out-degree')

  r.dev_off.call

  return {:dc_graph => png_filename}
end
  
def clustering_coefficient(pairs, system_name)
  cc = clustering_coefficients(pairs)
  ret = {}
  ret[:avg_cc] = cc.inject(0){ |sum, x| sum + x[1] } / cc.size.to_f

  
  png_filename = "#{system_name}-cc.png"
  ret[:cc_graph] = png_filename

  r = RSRuby.instance
  r.png(png_filename)
  
  d = pairs_log(cc).unzip
  r.plot('x' => d[0], 'y' => d[1], 
      'main' => "Clustering coefficient for #{system_name}",
      'xlab' => 'k (log)',
      'ylab' => \
      'clustering coefficient C(k) for a vertex with degree = k (log)')
  
  fit = lmfit(d[0], d[1])
  r.abline(fit[:a], fit[:b], :col => 'red', :lty => 2)
  ret.merge! :cc_exp => fit[:b], :cc_r2 => fit[:r2]

  r.abline(fit[:a], -1, :col => 'gold', :lty => 4)

  r.dev_off.call

  return ret
end

def compute_metrics(filename)
  pairs = read_rsf_pairs(filename)
  
  basename = File.basename(filename)

  puts basename
  ret = {:system => basename}

  puts '  degree_distribution'
  ret.merge! degree_distribution(pairs, basename)
  puts '  degree_correlation'
  ret.merge! degree_correlation(pairs, basename)
  puts '  clustering_coefficient'
  ret.merge! clustering_coefficient(pairs, basename)

  return ret
end

def create_report(filenames)

  fields = [
    {:id => :system, :label => 'system'},

    {:id => :dd_graph, :label => 'degree dist'},
    {:id => :gamma_in, :label => '&gamma<sub>in</sub>'},
    {:id => :in_r2, :label => 'R<sup>2</sup>'},
    {:id => :gamma_out, :label => '&gamma<sub>out</sub>'},
    {:id => :out_r2, :label => 'R<sup>2</sup>'},

    {:id => :cc_graph, :label => 'clust coef'},
    {:id => :cc_exp, :label => '&gamma;'},
    {:id => :cc_r2, :label => 'R<sup>2</sup>'},
    {:id => :avg_cc, :label => 'avg cc'},

    {:id => :dc_graph, :label => 'degree corr'},
  ]

  File.open('report.html', 'w') do |f|
    f.puts '<table border="1"><tr>'

    f.puts fields.map{|x| "<td>#{x[:label]}</td>"}.join + '</tr>'

    filenames.each do |filename|
      f.puts '<tr>'
      data = compute_metrics(filename)

      fields.each do |field|
        f.puts '<td>'
        value = data[field[:id]]

        if value.kind_of? Float
          f.puts '%.2f' % value
        elsif value.kind_of? String
          if value[-3..-1] == 'png'
            f.puts "<a href=\"#{value}\">" +
                "<img width=\"75%\" height=\"75%\" src=\"#{value}\"/></a>"
          else
            f.puts value
          end
        end

        f.puts '</td>'
      end

      f.puts '</tr>'
    end
    
    f.puts '</table>'
  end

end

if __FILE__ == $0
  filename = ARGV[0]
  if filename.nil?
    puts "Usage: #{File.basename($0)} filename

    "
    exit 1
  end

  create_report(ARGV)
  puts 'Done.'
end
