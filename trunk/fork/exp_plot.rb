#!/usr/bin/env ruby
require 'sequel'
require 'exp_clust'
require 'rsruby'

EXP = ClusteringExperiment.new

def plot_clusterers(pdf, model, y, x, plotargs)
  ds = EXP.db[<<-EOT
  SELECT DISTINCT pk_clusterer_config, nme_clusterer_config
  FROM decomposition
  INNER JOIN clusterer_config ON pk_clusterer_config = fk_clusterer_config
  WHERE fk_clusterer_config IS NOT NULL
  EOT
  ]

  configurations = ds.all
  r = RSRuby.instance
  r.pdf(pdf)
  plot_params = {:col => "white"}.merge(plotargs)
  r.plot([0], [0], plot_params)
  r.legend(0.8, 600, :pch => 1, 
    :col => configurations.map { |x| x[:pk_clusterer_config] },
    :legend => configurations.map { |x| x[:nme_clusterer_config] })

  configurations.each do |config|
    ds = EXP.db[<<-EOT
    SELECT mconf.#{x} AS x, avg(dec.#{y}) AS y, count(*) AS count, cconf.nme_clusterer_config
    FROM decomposition AS dec
    INNER JOIN network AS net ON net.pk_network = dec.fk_network
    INNER JOIN model_config mconf ON mconf.pk_model_config = net.fk_model_config
    INNER JOIN clusterer_config cconf ON cconf.pk_clusterer_config = dec.fk_clusterer_config
    WHERE dec.#{y} IS NOT NULL
      AND mconf.fk_model = #{model}
      AND dec.fk_clusterer_config = #{config[:pk_clusterer_config]} 
      AND dec.reference = FALSE
    GROUP BY 1, 4
    ORDER BY 4, 1;
    EOT
    ]

    #puts ds.sql
    all = ds.all
    p all

    mojos = all.map { |x| 1000 - x[:y].to_f}
    mixings = all.map { |x| x[:x].to_f }
    r.points(:x => mixings, :y => mojos, :col => config[:pk_clusterer_config])
    r.lines(:x => mixings, :y => mojos, :col => config[:pk_clusterer_config])
  end

  r.dev_off.call

  system("scp -P 2299 #{pdf} app:./public_html")
end

plot_clusterers('x.pdf', ClusteringExperiment::MODEL_LF, 'mojo', 'mixing', :xlim => [0,1], :ylim => [0, 1000])


