require 'sequel'
require 'exp_clust'
require 'rsruby'

exp = ClusteringExperiment.new

ds = exp.db[<<-EOT
SELECT DISTINCT cl.fkalgorithm, cl.fkalgparams
FROM clustering cl
EOT
]

configurations = ds.all

r = RSRuby.instance
r.plot(:x => [0], :y => [0], :col => "white",
    :xlim => [0, 1], :ylim => [0, 1000])

i = 0
configurations.each do |config|
  i += 1
  ds = exp.db[<<-EOT
  SELECT par.mixing, avg(int4(mojo)) AS avg
  FROM clustering cl
  INNER JOIN synthetic_network snet ON snet.pksynthetic_network = cl.fksynthetic_network
  INNER JOIN lf_params par ON par.pkparams = snet.fkparams
  INNER JOIN algorithm alg ON alg.pkalgorithm = cl.fkalgorithm
  WHERE mojo IS NOT NULL
    AND cl.fkalgparams = #{config[:fkalgparams]}
    AND cl.fkalgorithm = #{config[:fkalgorithm]}
  GROUP BY par.mixing
  ORDER BY par.mixing;
  EOT
  ]

  all = ds.all
  p config
# {:fkalgorithm=>1, :fkalgparams=>1}
# [{:mixing=>0.5, :avg=>#<BigDecimal:23bc938,'0.8056530242 196606657E3',27(36)>}]

  mojos = all.map { |x| 1000 - x[:avg].to_f }
  mixings = all.map { |x| x[:mixing].to_f }
  r.points(:x => mixings, :y => mojos, :col => i)
  r.lines(:x => mixings, :y => mojos, :col => i)

  gets
end


#r.png(png_filename)
#r.dev_off.call
