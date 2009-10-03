require 'sequel'
require 'exp_clust'
require 'rsruby'

exp = ClusteringExperiment.new

ds = exp.db[<<-EOT
SELECT DISTINCT fk_clusterer_config
FROM decomposition
WHERE fk_clusterer_config IS NOT NULL
EOT
]

configurations = ds.all

r = RSRuby.instance
r.pdf('x.pdf')
r.plot(:x => [0], :y => [0], :col => "white",
    :xlim => [0, 1], :ylim => [0, 1000])

i = 0
configurations.each do |config|
  i += 1
  ds = exp.db[<<-EOT
  SELECT mconf.mixing, avg(dec.mojo) AS avg, count(*) AS count
  FROM decomposition AS dec
  INNER JOIN network AS net ON net.pk_network = dec.fk_network
  INNER JOIN model_config mconf ON mconf.pk_model_config = net.fk_model_config
  WHERE dec.mojo IS NOT NULL
    AND mconf.fk_model = #{ClusteringExperiment::MODEL_LF}
    AND dec.fk_clusterer_config = #{config[:fk_clusterer_config]} 
    AND dec.reference = FALSE
  GROUP BY mconf.mixing
  ORDER BY mconf.mixing;
  EOT
  ]

  all = ds.all
  p all

  mojos = all.map { |x| 1000 - x[:avg].to_f }
  mixings = all.map { |x| x[:mixing].to_f }
  #p mojos
  #p mixings
  r.points(:x => mixings, :y => mojos, :col => i)
  r.lines(:x => mixings, :y => mojos, :col => i)

end

r.dev_off.call
system 'scp -P 2299 x.pdf app:./public_html'

