#!/usr/bin/env ruby

require 'exp_clust'

class ClusteringExperiment

  def drop_all_tables
    tables=@db[<<-EOT
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema='public' A
      ND table_type != 'VIEW' 
      AND table_name NOT LIKE 'pg_ts_%%'
      EOT
      ].all.map { |h| h.values[0] }
    tables.each { |t| @db.drop_table t }
  end

  def self.xxx_test_insert_params
    exp = ClusteringExperiment.new
    #exp.drop_all_tables
    exp.create_tables

    p exp.insert_synthetic_network_params(ClusteringExperiment::MODEL_LF, 
      :seed => 0, 
      :n => 1000, 
      :avgk => 10, 
      :maxk => 100, 
      :mixing => 0.5,
      :expdegree => 2.5,
      :expsize => 1.0,
      :minm => 5,
      :maxm => nil)
    
    p exp.insert_synthetic_network_params(ClusteringExperiment::MODEL_CGW, 
      :seed => 0,
      :p1 => 0.6,
      :p2 => 0.2,
      :p3 => 0.0,
      :p4 => 0.2,
      :e1 => 2,
      :e2 => 1,
      :e3 => 1,
      :e4 => 1,
      :n => 1000,
      :m => 16,
      :alpha => 100)

    if exp.db[:architecture].empty?
      exp.db[:architecture].insert(:arch_name => 'dummy', :arch_arc => '0 1', :arch_mod => '0 0')
    end
    arch_id = exp.db[:architecture].first[:pkarchitecture]

    p exp.insert_synthetic_network_params(ClusteringExperiment::MODEL_BCR,
        :seed => 0,
        :n => 1000,
        :fkarchitecture => arch_id,
        :p1 => 0.7,
        :p2 => 0.2,
        :p3 => 0.1,
        :din => 2,
        :dout => 3,
        :mu => 0.3)

#    p exp.db[:synthetic_network].filter(:fkmodel => ClusteringExperiment::MODEL_BCR).inner_join(:bcr_params, :pkparams => :fkparams)
#      .inner_join(:architecture, :pkarchitecture => :fkarchitecture)
#      .all

    #exp.db[:clustering].delete
    #exp.db[:clustering].insert(
    #  :fksynthetic_network => 0,
    #  :fkalgorithm => ALGORITHM_ACDC,
    #  :fkalgparams => 1)

    exp.db[:algorithm].delete
    exp.db[:algorithm].insert :pkalgorithm => ALGORITHM_ACDC, :algname => 'ACDC'
    exp.db[:algorithm].insert :pkalgorithm => ALGORITHM_HCAS, :algname => 'HCAS'
    exp.db[:acdc_params].delete
    exp.db[:acdc_params].insert :top_level_clusters => true
    exp.db[:clustering].delete
  end
end

if __FILE__ == $0
  ClusteringExperiment::xxx_test_insert_params

  exp = ClusteringExperiment.new
  exp.generate_all_missing_networks
  exp.do_clustering

  #p exp.db[:synthetic_network].filter(:arc => '123').count
  #p exp.db[:synthetic_network].update(:arc => nil)
end

