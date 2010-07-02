#!/usr/bin/env ruby

require 'postgres'

# PGconn.connect(pghost,pgport,pgoptions,pgtty,dbname,login,password)
$conn = PGconn.connect('localhost', 5555, nil, nil, 'rodrigo', 'rodrigo', 'rodrigodb')

MODEL_BCR = 1 
MODEL_CGW = 2 
MODEL_LFR = 3 
THRESHOLD = 0.809316572577955

SQL_THRESHOLD = " CASE WHEN s_score >= #{THRESHOLD} THEN 'Y' ELSE 'N' END "

def sql_model(model, params)
  return <<EOT
  SELECT #{params}, #{SQL_THRESHOLD}
  FROM model_config mc
  INNER JOIN network net ON net.fk_model_config = mc.pk_model_config
  WHERE mc.fk_model = #{model}
  AND fk_dataset IN (1,9)
  AND seed = 0
EOT
end

def do_model(basename, model, params)
  puts "Model #{basename}"
  File.open("#{basename}.csv", "w") do |f|
    f.puts "#{params},swlike"
    $conn.exec(sql_model(model, params)).result.each do |tuple|
      f.puts tuple.join(",")
    end

    system "java -cp weka.jar weka.classifiers.rules.OneR -B 6 -v -t #{basename}.csv > #{basename}.txt"
  end
end

do_model("bcr", MODEL_BCR, "fk_architecture,p1,p2,p3,din,dout,mu")
do_model("cgw", MODEL_CGW, "p1,p2,p3,p4,e1,e2,e3,e4,m,alpha")
do_model("lfr", MODEL_LFR, "avgk,maxk,mixing,expdegree,expsize,minm,maxm")


