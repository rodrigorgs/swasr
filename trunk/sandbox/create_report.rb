#!/usr/bin/env ruby

require 'pstore'

#class XmlReturn
#  def method_missing(name, *params)
#    "<#{name}>#{yield.to_s}</#{name}>" # params as hash of attributes
#  end
#end

class XmlPrint
  def initialize(outstream)
    @out = outstream
  end

  def method_missing(name, *params, &block)
    if %w(print printf puts).include? name.to_s
      @out.send(name, *params)
    else
      hash = {}
      hash.merge! params[0] if params[0].kind_of? Hash
      opts = hash.to_a.map{ |x, y| "#{x}=#{y.to_s.dump}"}.join(' ')

      @out.puts "<#{name} %s>" % opts
      block.call unless block.nil?
      @out.puts "</#{name}>"
    end
  end
end

class CsvPrint
  def initialize(outstream)
    @out = outstream
  end

  def tr
    yield
    @out.puts
  end

  def td
    yield
    @out.print "\t"
  end

  def print(str)
    @out.print str.to_s
  end

  def puts(str)
    @out.print str.to_s
  end

  def method_missing(name, *params)
    yield
  end
end

def create_report(pstore_filename, out)
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
  
  pstore = PStore.new(pstore_filename)
  pstore.transaction do
    File.open('report.html', 'w') do |f|
      out.table :border => 1 do
        out.tr do
          fields.each { |x| out.td { out.print x[:label] }}
        end
        #f.puts fields.map{|x| "<td>#{x[:label]}</td>"}.join + '</tr>'

        pstore.roots.sort.each do |filename|
          out.tr do
            data = pstore[filename]

            fields.each do |field|
              out.td do
                value = data[field[:id]]

                if value.kind_of? Float
                  out.print '%.2f' % value
                elsif value.kind_of? String
                  if value[-3..-1] == 'png'
                    out.print "<a href=\"#{value}\">" +
                    "<img width=\"75%\" height=\"75%\" src=\"#{value}\"/></a>"
                  else
                    out.print value
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

if __FILE__ == $0
  filename = ARGV[0]
  if filename.nil?
    puts "Usage: #{File.basename($0)} pstore_filename printer

    where printer is one of CsvPrint, XmlPrint
    "
    exit 1
  end

  klass = Kernel.const_get(ARGV[1] || :XmlPrint)
  out = klass.new(STDOUT)
  create_report(filename, out)
end
