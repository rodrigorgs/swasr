#!/usr/bin/env ruby

require 'pstore'

def create_report(pstore_filename)
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
      f.puts '<table border="1"><tr>'

      f.puts fields.map{|x| "<td>#{x[:label]}</td>"}.join + '</tr>'

      pstore.roots.sort.each do |filename|
        f.puts '<tr>'
        #data = compute_metrics(filename)
        data = pstore[filename]

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
end

if __FILE__ == $0
  filename = ARGV[0]
  if filename.nil?
    puts "Usage: #{File.basename($0)} pstore_filename

    "
    exit 1
  end

  create_report(filename)
end
