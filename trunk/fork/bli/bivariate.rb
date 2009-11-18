#!/usr/bin/env ruby

require 'rsruby'
#require 'scruffy' # plotting

def numeric?(object)
  true if Float(object) rescue false
end

def read_csv(filename)
  y = IO.readlines(filename).map { |line| line.chomp.split("\t") }
  y.each do |x|
    x.map! { |v| numeric?(v) ? v.to_f : v }
  end
  return y
end

class Array
  def column(i)
    map{ |row| row[i] }
  end

  def avg
    nil_count = 0
    self.inject(0.0) { |sum, x| x.nil? ? (nil_count += 1; sum) : sum + x } / (self.size.to_f - nil_count)
  end
end

class Float
  def to_s
    "%.2f" % self
  end
end

if __FILE__ == $0
  puts "Para cada faixa de valores da variavel independente, mostra o valor
medio da variavel dependente (mojosim)."
  puts

  csv = read_csv('/tmp/bli.csv')
  headers = csv[0]
  data = csv[1..-1]
  cols = headers.size

  y = data.column(cols)
  (cols-1).times do |i|
    x = data.column(i)
    group = nil
    if x[0].kind_of?(String)
      group = data.group_by { |row| row[i] }
    else
      minx = x.min
      maxx = x.max
      deltax = maxx - minx
      stepx = deltax / 5.0
      group = data.group_by { |row| ((row[i] - minx) / stepx).to_i }
    end
    xy = group.to_a.map do |g| [g[0], g[1][cols-1]]
      left = g[0]
      right = g[1].column(cols-1).avg
      [left, right]
    end.sort_by { |a, b| a }

    puts headers[i]
    print "  "; p xy
  end
end
