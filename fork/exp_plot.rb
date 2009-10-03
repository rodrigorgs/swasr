#!/usr/bin/env ruby
require 'sequel'
require 'exp_clust'
require 'rsruby'

exp = ClusteringExperiment.new

ds = exp.db[<<-EOT
SELECT DISTINCT pk_clusterer_config, nme_clusterer_config
FROM decomposition
INNER JOIN clusterer_config ON pk_clusterer_config = fk_clusterer_config
WHERE fk_clusterer_config IS NOT NULL
EOT
]

configurations = ds.all
p configurations

r = RSRuby.instance
r.pdf('x.pdf')
r.plot(:x => [0], :y => [0], :col => "white",
    :xlim => [0, 1], :ylim => [0, 1000])
r.legend(0.8, 600, :pch => 1, 
  :col => configurations.map { |x| x[:pk_clusterer_config] },
  :legend => configurations.map { |x| x[:nme_clusterer_config] })

configurations.each do |config|
  ds = exp.db[<<-EOT
  SELECT mconf.mixing, avg(dec.mojo) AS avg, count(*) AS count, cconf.nme_clusterer_config
  FROM decomposition AS dec
  INNER JOIN network AS net ON net.pk_network = dec.fk_network
  INNER JOIN model_config mconf ON mconf.pk_model_config = net.fk_model_config
  INNER JOIN clusterer_config cconf ON cconf.pk_clusterer_config = dec.fk_clusterer_config
  WHERE dec.mojo IS NOT NULL
    AND mconf.fk_model = #{ClusteringExperiment::MODEL_LF}
    AND dec.fk_clusterer_config = #{config[:pk_clusterer_config]} 
    AND dec.reference = FALSE
  GROUP BY 1, 4
  ORDER BY 4, 1;
  EOT
  ]

  all = ds.all
  p all

  mojos = all.map { |x| 1000 - x[:avg].to_f }
  mixings = all.map { |x| x[:mixing].to_f }
  #p mojos
  #p mixings
  r.points(:x => mixings, :y => mojos, :col => config[:pk_clusterer_config])
  r.lines(:x => mixings, :y => mojos, :col => config[:pk_clusterer_config])
end

r.dev_off.call
system 'scp -P 2299 x.pdf app:./public_html'

