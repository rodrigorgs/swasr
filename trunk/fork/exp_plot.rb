#!/usr/bin/env ruby
require 'sequel'
require 'exp_clust'
require 'rsruby'
require 'ostruct'

EXP = ClusteringExperiment.new

def big_view(where='1=1')
    ds = EXP.db[<<-EOT
    SELECT 
      nme_model, 
      CASE 
        WHEN nme_clusterer_config IS NULL THEN '_NULL'
        ELSE nme_clusterer_config
      END AS nme_clusterer_config, 
      mixing, mu, alpha, 
      avg(mojo) as mojo, 
      avg((n - mojo) / n::float) as mojosim,
      avg(n_modules) as n_modules, 
      avg(n_subfive) as n_subfive, 
      avg(min_module_size) as min_module_size, 
      avg(max_module_size) as max_module_size,
      avg(purity) AS purity,
      avg(nmi) AS nmi,
      count(*) as count
    FROM view_decomposition
    WHERE (#{where})
    GROUP BY 1, 2, 3, 4, 5
    ORDER BY 1, 3, 4, 2;
    EOT
    ]

    return ds.all
end

def _convert_to_r(array)
  return array.map do |x|
    x.class == BigDecimal ? x.to_f : x
  end
end

def plot_multiple_xy(filename, data, colx, coly, colseries, plotargs, &filter)
  data = data.select { |row| filter.call(row) } if filter
  valseries = data.map { |row| row[colseries] }.sort.uniq

  r = RSRuby.instance
  r.pdf(filename)
  plot_params = {:col => "white"}.merge(plotargs)
  r.plot([0], [0], plot_params)
  r.legend('topright', :pch => 1.upto(valseries.size).to_a, 
    :col => 1.upto(valseries.size).to_a,
    :legend => valseries)

  File.open("#{filename}.htm", 'w') do |f|
    valseries.each_with_index do |val, i|
      series = data.select { |row| row[colseries] == val }.sort_by { |row| row[colx] }
      x = _convert_to_r(series.map { |row| row[colx] })
      y = _convert_to_r(series.map { |row| row[coly] })
      p x
      p y
      xnils = x.size.times.to_a.select { |i| x[i] == nil }
      ynils = y.size.times.to_a.select { |i| y[i] == nil }
      nils = (xnils + ynils)
      nils = (nils & nils).sort.reverse
      nils.each do |i|
        x[i] = nil
        y[i] = nil
      end
      x.compact!
      y.compact!

      next if x.size == 0
      #x.map! { |a| a || 0 }
      #y.map! { |a| a || 0 }
      #next if x.include?(nil) || y.include?(nil)
      #p x 
      #p y
      r.points(:x => x, :y => y, :col => i+1, :pch => i+1)
      r.lines(:x => x, :y => y, :col => i+1)

      f.puts("<h2>#{val}</h2>")
      f.puts("<table border='1'><tr><th>#{colx}</th><th>#{coly}</th></tr>")
      0.upto(x.size - 1) { |j| f.puts("<tr><td>#{x[j]}</td><td>#{y[j]}</td></tr>") }
      f.puts("</table>")
    end
  end

  r.dev_off.call
  system("scp -P 2299 #{filename} #{filename}.htm app:./public_html/plots")
end

def view_realism
  EXP.db[<<-EOT
    SELECT nme_model, 
      CASE
        WHEN mixing IS NOT NULL THEN mixing
        WHEN mu IS NOT NULL THEN mu
      END AS mixing ,
      avg(s_score) AS s_score
    FROM view_realism
    WHERE (mixing IS NOT NULL OR mu IS NOT NULL)
    AND s_score IS NOT NULL
    GROUP BY 1, 2
    ORDER BY 1, 2
  EOT
  .all
end

class Measure
  attr_accessor :name, :column, :description, :range, :log
end

mojosim = Measure.new
mojosim.name = 'mojosim'
mojosim.column = :mojosim
mojosim.description = 'MoJoSim'
mojosim.range = [0, 1]
mojosim.log = false

nmi = Measure.new
nmi.name = 'nmi'
nmi.column = :nmi
nmi.description = 'normalized mutual information'
nmi.range = [0, 1]
nmi.log = false

def plotdm(data, measure, args={})
  model = data[0][:nme_model]
  plot_multiple_xy("plots/dm_#{model}-#{measure}.pdf", data,
    :mixing, measure,
    :nme_clusterer_config,
    :main => model, 
    :xlim => [0, 1],
    :ylim => args[:ylim] || [0, 1],
    :xlab => 'mixing',
    :ylab => measure.to_s)
end


#data = big_view("expdegree = 2.25 AND minm = 20 AND maxm = 50") # AND pk_clusterer_config IS NOT NULL") # AND cconf.pk_clusterer_config = #{CE::CONFIG_INFOMAP}")
#
#plotdm data, :nmi
#plotdm data, :mojosim
#plotdm data, :n_modules, :ylim => [1, 1000]

data = big_view("synthetic = false") # AND pk_clusterer_config IS NOT NULL") # AND cconf.pk_clusterer_config = #{CE::CONFIG_INFOMAP}")

plot_multiple_xy "plots/real.pdf", data,
  :pk_network, :nmi,
  :nme_clusterer_config,
  :main => 'Real',
  :xlim => [0, 100],
  :ylim => [0, 1],
  :xlab => '', :ylab => ''

#p data
#p data.map { |x| x[:nmi] }
#plot_multiple_xy "plots/_lf-nmi.pdf", data,
#  :mixing, :nmi,
#  :nme_clusterer_config,
#  :main => 'LF', :xlim => [0,1], :ylim => [0,1],
#  :xlab => 'mixing parameter', :ylab => 'normalized mutual information'

exit 1

##############################################################################
all_data = big_view

mhash = {
  :bcr => OpenStruct.new(
    :nme => 'BCR+',
    :mixing => :mu,
    :nme_mixing => 'mu',
    :range_mixing => [0, 1],
    :log => false),
  :lf => OpenStruct.new(
    :nme => 'LF',
    :mixing => :mixing,
    :nme_mixing => 'mixing parameter',
    :range_mixing => [0, 1],
    :log => false),
  :cgw => OpenStruct.new(
    :nme => 'CGW',
    :mixing => :alpha,
    :nme_mixing => 'alpha',
    :range_mixing => [1, 1000],
    :log => true)
}

[:bcr, :lf, :cgw].each do |model|
  minfo = mhash[model]

  plot_multiple_xy("plots/#{minfo.nme}-mojo.pdf", all_data,
  minfo.mixing, 
  :mojosim, 
  :nme_clusterer_config, 
  :main => minfo.nme, :xlim => minfo.range_mixing, :ylim => [0,1],
  :log => minfo.log ? 'x' : '',
  :xlab => minfo.nme_mixing, :ylab => 'MoJoSim') { |row| 
  row[:nme_model] == minfo.nme && row[:nme_clusterer_config] != nil }
  
  plot_multiple_xy("plots/#{minfo.nme}-purity.pdf", all_data,
  minfo.mixing, 
  :purity, 
  :nme_clusterer_config, 
  :main => minfo.nme, :xlim => minfo.range_mixing, :ylim => [0,1],
  :log => minfo.log ? 'x' : '',
  :xlab => minfo.nme_mixing, :ylab => 'purity') { |row| 
  row[:nme_model] == minfo.nme && row[:nme_clusterer_config] != nil && row[:purity] != nil}
  
  plot_multiple_xy("plots/#{minfo.nme}-nmi.pdf", all_data,
  minfo.mixing, 
  :nmi, 
  :nme_clusterer_config, 
  :main => minfo.nme, :xlim => minfo.range_mixing, :ylim => [0,1],
  :log => minfo.log ? 'x' : '',
  :xlab => minfo.nme_mixing, :ylab => 'normalized mutual information') { |row| 
  row[:nme_model] == minfo.nme && row[:nme_clusterer_config] != nil && row[:nmi] != nil}

  plot_multiple_xy("plots/#{minfo.nme}-n_modules.pdf", all_data,
  minfo.mixing,
  :n_modules,
  :nme_clusterer_config,
  :main => minfo.nme, :xlim => minfo.range_mixing, :ylim => [0, 1000],
  :log => minfo.log ? 'x' : '',
  :xlab => minfo.nme_mixing, :ylab => 'modules') { |row|
  row[:nme_model] == minfo.nme }

  plot_multiple_xy("plots/#{minfo.nme}-n_subfive.pdf", all_data,
  minfo.mixing,
  :n_subfive,
  :nme_clusterer_config,
  :main => minfo.nme, :xlim => minfo.range_mixing, :ylim => [0, 1000],
  :log => minfo.log ? 'x' : '',
  :xlab => minfo.nme_mixing, :ylab => 'modules < 5 nodes') { |row|
  row[:nme_model] == minfo.nme }
  
  plot_multiple_xy("plots/#{minfo.nme}-sub5-mojo.pdf", all_data,
  :n_subfive,
  :mojosim,
  :nme_clusterer_config,
  :main => minfo.nme, :xlim => [0, 1000], :ylim => [0, 1],
  :xlab => 'modules < 5 nodes', :ylab => 'MoJoSim') { |row|
  row[:nme_model] == minfo.nme }
end

