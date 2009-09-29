#!/usr/bin/env ruby

require 'exp_clust'

class ClusteringExperiment

  def self.xxx_test_insert_params
    exp = ClusteringExperiment.new
    exp.drop_all_tables
    exp.create_tables

    exp.insert_synthetic_network_params(ClusteringExperiment::MODEL_LF, 
      :seed => 0, 
      :n => 300, 
      :avgk => 10, 
      :maxk => 100, 
      :mixing => 0.5,
      :expdegree => 2.5,
      :expsize => 1.0,
      :minm => 5,
      :maxm => nil)
    
    exp.insert_synthetic_network_params(ClusteringExperiment::MODEL_CGW, 
      :seed => 0,
      :p1 => 0.6,
      :p2 => 0.2,
      :p3 => 0.0,
      :p4 => 0.2,
      :e1 => 2,
      :e2 => 1,
      :e3 => 1,
      :e4 => 1,
      :n => 300,
      :m => 16,
      :alpha => 100)

    if exp.db[:architecture].empty?
      exp.db[:architecture].insert(:arch_name => 'dummy', :arch_arc => '0 1', :arch_mod => '0 0')
    end
    arch_id = exp.db[:architecture].first[:pkarchitecture]

    exp.insert_synthetic_network_params(ClusteringExperiment::MODEL_BCR,
        :seed => 0,
        :n => 300,
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

    exp.db[:algorithm].delete
    exp.db[:algorithm].insert :pkalgorithm => ALGORITHM_ACDC, :algname => 'ACDC'
    exp.db[:algorithm].insert :pkalgorithm => ALGORITHM_HCAS, :algname => 'HCAS'

    exp.db[:hcas_params].delete
    exp.db[:hcas_params].insert(
      :linkage => 'C',
      :coefficient => 'aJ',
      :cut_height => 0.90)
    #exp.db[:hcas_params].insert(
    #  :linkage => 'S',
    #  :coefficient => 'aJ',
    #  :cut_height => 0.75)

    exp.db[:acdc_params].delete
    exp.db[:acdc_params].insert(
        :top_level_clusters => true,
        :patterns => "+so",
        :max_cluster_size => 99999)
    exp.db[:clustering].delete
  end

  def drop_all_tables
    tables=@db[<<-EOT
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema='public'
      AND table_type != 'VIEW' 
      AND table_name NOT LIKE 'pg_ts_%%'
      EOT
      ].all.map { |h| h.values[0] }
    tables.each { |t| @db.drop_table t }
  end
end

if __FILE__ == $0
  #ClusteringExperiment::xxx_test_insert_params

  exp = ClusteringExperiment.new
  p exp.db[:clustering].filter(:pkclustering => 9876).first

  #0.upto(10).map { |x| x / 10.0 }.each do |mixing|
  #p mixing
  #100.times do |seed|
  #  exp.insert_synthetic_network_params(ClusteringExperiment::MODEL_LF, 
  #    :seed => seed, 
  #    :n => 1000, 
  #    :avgk => 15, 
  #    :maxk => 300, 
  #    :mixing => mixing,
  #    :expdegree => 2.5,
  #    :expsize => 1.0,
  #    :minm => 5,
  #    :maxm => nil)
  #end
  #end

  #exp.generate_all_missing_networks
  exp.do_clustering(ClusteringExperiment::ALGORITHM_ACDC)
  #exp.compute_mojos
end

