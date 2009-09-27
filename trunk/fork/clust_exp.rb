require 'rubygems'
require 'sequel' 
  # http://sequel.rubyforge.org/static/mwrc2009_presentation.html

require 'network_models'

class ClusteringExperiment
  MODEL_BCR = 0
  MODEL_CGW = 1
  MODEL_LF = 2

  HASH_MODEL_TO_TABLE = {
    MODEL_BCR => :bcr_params, 
    MODEL_CGW => :cgw_params,
    MODEL_LF => :lf_params}

  ALGORITHM_ACDC = 1
  ALGORITHM_HCAS = 2

  HASH_ALGORITHM_TO_TABLE = {
    ALGORITHM_ACDC => :acdc_params,
    ALGORITHM_HCAS => :hcas_params}

  def drop_all_tables
    #sequences = @db["SELECT sequence_name FROM information_schema.sequences WHERE sequence_schema='public'"].all
    #p sequences
    tables=@db["SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type != 'VIEW' AND table_name NOT LIKE 'pg_ts_%%'"].all.map { |h| h.values[0] }
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

  attr_reader :db

  def initialize
    #@db = Sequel.sqlite('teste.db')
    @db = Sequel.postgres('rodrigo', :user => 'rodrigo', :password => 'rodrigodb', :host => 'mainha')
  end

  def create_tables
    @db.create_table? :acdc_params do
      primary_key :pkalgparams
      Boolean :top_level_clusters
    end

    @db.create_table? :hcas_params do
      primary_key :pkalgparams
      Boolean :single_linkage
      Float :cut_height
    end

    @db.create_table? :algorithm do
      Integer :pkalgorithm
      String :algname
    end

    @db.create_table? :clustering do
      primary_key :pkclustering
      Integer :fksynthetic_network
      Integer :fkalgorithm
      Integer :fkalgparams
      String :clusteringmod
      String :mojo
      Integer :n_modules
      Integer :min_module_size
      Integer :max_module_size
    end

    @db.create_table? :synthetic_network do
      primary_key :pksynthetic_network
      Integer :fkmodel
      Integer :fkparams
      String :arc
      String :mod
    end

    @db.create_table? :cgw_params do
      primary_key :pkparams
      Integer :seed
      Float :p1
      Float :p2
      Float :p3
      Float :p4
      Integer :e1
      Integer :e2
      Integer :e3
      Integer :e4
      Integer :n
      Integer :m
      Float :alpha
    end

    @db.create_table? :bcr_params do
      primary_key :pkparams
      Integer :seed
      Integer :n
      Integer :fkarchitecture
      Float :p1
      Float :p2
      Float :p3
      Float :din
      Float :dout
      Float :mu
    end

    @db.create_table? :lf_params do
      primary_key :pkparams
      Integer :n
      Float :avgk
      Integer :maxk
      Float :mixing
        # parameters below are optional
      Integer :seed, :null => true
      Float :expdegree, :null => true
      Float :expsize, :null => true
      Integer :minm, :null => true
      Integer :maxm, :null => true
    end

    @db.create_table? :architecture do
      primary_key :pkarchitecture
      String :arch_name
      String :arch_arc
      String :arch_mod
    end

    @db.create_table? :motifs do
      primary_key :pkmotifs
      Float :m1
      Float :m2
      Float :m3
      Float :m4
      Float :m5
      Float :m6
      Float :m7
      Float :m8
      Float :m9
      Float :m10
      Float :m11
      Float :m12
      Float :m13
    end
  end

  def insert_safe(table, values)
    ret = false
    dataset = @db[table].filter(values)
    count = dataset.count
    if count == 0
      @db[table].insert(values)
      ret = true
    elsif count > 1
      raise RuntimeError, 'More than 1 row returned.'
    end

    return ret
  end

  def insert_synthetic_network_params(model, params)
    table = HASH_MODEL_TO_TABLE[model]
    raise RuntimeError, "Invalid model" if table.nil?

    insert_safe table, params
    id = @db[table].filter(params).first[:pkparams]
    insert_safe :synthetic_network, :fkmodel => model, :fkparams => id
  end

  def dataset_params(model)
    params_table = HASH_MODEL_TO_TABLE[model]
    dataset = @db[:synthetic_network].filter(:fkmodel => model)
              .inner_join(params_table, :pkparams => :fkparams)
    if model == MODEL_BCR
      dataset = dataset.inner_join(:architecture, :pkarchitecture => :fkarchitecture)
    end
    return dataset
  end

  def generate_network(model, params)
    return (case model
    when MODEL_BCR then generate_bcrplus(params)
    when MODEL_CGW then generate_cgw(params)
    when MODEL_LF  then generate_lf(params)
    else raise RuntimeError, 'Invalid model'
    end)
  end

  
  def generate_all_missing_networks
    HASH_MODEL_TO_TABLE.keys.each do |model|
      generate_missing_networks(model)
    end
  end

  def generate_missing_networks(model)
    dataset = dataset_params(model)
    dataset.filter(:arc => nil).each do |row|
      g = generate_network(model, row)
      @db[:synthetic_network].filter(:pksynthetic_network => row[:pksynthetic_network]).update(:arc => g[0], :mod => g[1])
    end
  end

  def prepare_clustering_for_algorithm(algorithm)
    params_table = HASH_ALGORITHM_TO_TABLE[algorithm]
#    dataset_all = @db[:synthetic_network].select(:pksynthetic_network)
#              .join_table(:cross, :algorithm, nil).select_more(:pkalgorithm)
#              .join_table(:cross, params_table, nil).select_more(:pkalgparams)

    dataset_all = @db[<<-EOT
      SELECT sn.pksynthetic_network AS fksynthetic_network,
        pkalgorithm AS fkalgorithm,
        pkalgparams AS fkalgparams
      FROM synthetic_network AS sn
      CROSS JOIN algorithm AS alg
      CROSS JOIN #{params_table} AS par
    EOT
    ]

    puts "prepare_clustering_for_algorithm(#{params_table})"
    p dataset_all.all
    dataset_created = @db[:clustering].select(:fksynthetic_network,
                                              :fkalgorithm,
                                              :fkalgparams)

    dataset_to_create = dataset_all.except(dataset_created)

    @db[:clustering].insert_multiple(dataset_to_create.all)
  end

  def prepare_clustering
    HASH_ALGORITHM_TO_TABLE.keys.each do |algorithm|
      prepare_clustering_for_algorithm(algorithm)
    end
  end

  def do_clustering
    prepare_clustering
    dataset = @db[:synthetic_network]
              .inner_join(:clustering, :fksynthetic_network => :pksynthetic_network)
              .inner_join(:acdc_params, :pkalgparams => :fkalgparams)
              .filter(:fkalgorithm => 0)

    dataset.each do |row|
      mod = Clusterer::acdc(dataset[:arc])
      # TODO: Update table
    end
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

