#!/usr/bin/env ruby
require 'sequel'
require 'exp_clust'
require 'rsruby'
require 'ostruct'

EXP = ClusteringExperiment.new

def big_view
    ds = EXP.db[<<-EOT
    SELECT 
      nme_model, 
      CASE 
        WHEN cconf.nme_clusterer_config IS NULL THEN '_NULL'
        ELSE cconf.nme_clusterer_config
      END AS nme_clusterer_config, 
      mconf.mixing, mconf.mu, mconf.alpha, 
      avg(dec.mojo) as mojo, 
      avg((mconf.n - dec.mojo) / mconf.n::float) as mojosim,
      avg(dec.n_modules) as n_modules, 
      avg(dec.n_subfive) as n_subfive, 
      avg(dec.min_module_size) as min_module_size, 
      avg(dec.max_module_size) as max_module_size,
      avg(dec.purity) AS purity,
      avg(dec.nmi) AS nmi,
      count(*) as count
    FROM decomposition AS dec
    INNER JOIN network AS net ON net.pk_network = dec.fk_network
    INNER JOIN model_config mconf ON mconf.pk_model_config = net.fk_model_config
    INNER JOIN model ON model.pk_model = mconf.fk_model
    LEFT JOIN clusterer_config cconf ON cconf.pk_clusterer_config = dec.fk_clusterer_config
    WHERE dec.mojo IS NOT NULL
      AND dec.n_modules IS NOT NULL
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
  data = data.select { |row| filter.call(row) }
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

# mojo vs mixing, LF
all_data = big_view

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

