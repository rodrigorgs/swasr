require 'rubygems'
require 'sequel' 
  # http://sequel.rubyforge.org/static/mwrc2009_presentation.html

require 'network_models'
require 'mojosim'
require 'clustering'

class ClusteringExperiment
  attr_reader :db
  
  MODEL_BCR = 1
  MODEL_CGW = 2
  MODEL_LF = 3

  HASH_MODEL_TO_TABLE = {
    MODEL_BCR => :bcr_params, 
    MODEL_CGW => :cgw_params,
    MODEL_LF => :lf_params}

  ALGORITHM_ACDC = 1
  ALGORITHM_HCAS = 2

  HASH_ALGORITHM_TO_TABLE = {
    ALGORITHM_ACDC => :acdc_params,
    ALGORITHM_HCAS => :hcas_params}

  def initialize
    #@db = Sequel.sqlite('teste.db')
    @db = Sequel.postgres('rodrigo', 
        :user => 'rodrigo', 
        :password => 'rodrigodb', 
        :host => 'mainha')
  end

  def create_tables
    @db.create_table? :acdc_params do
      primary_key :pkalgparams
      Boolean :top_level_clusters
      Integer :max_cluster_size
      String :patterns, :size => 4
    end

    @db.create_table? :hcas_params do
      primary_key :pkalgparams
      String :linkage, :size => 1
      String :coefficient, :size => 2
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
      index [:fksynthetic_network, :fkalgorithm, :fkalgparams], :unique => true
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
      index [:fkmodel, :fkparams], :unique => true
      String :arc
      String :mod
      Integer :fkexperiment, :default => 1
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
      puts 'generate network'
      @db[:synthetic_network].filter(:pksynthetic_network => row[:pksynthetic_network]).update(:arc => g[0], :mod => g[1])
    end
  end

  def prepare_clustering_for_algorithm(algorithm)
    params_table = HASH_ALGORITHM_TO_TABLE[algorithm]
#    dataset_all = @db[:synthetic_network].select(:pksynthetic_network)
#              .join_table(:cross, :algorithm, nil).select_more(:pkalgorithm)
#              .join_table(:cross, params_table, nil).select_more(:pkalgparams)

    dataset = @db[<<-EOT
      SELECT sn.pksynthetic_network AS fksynthetic_network,
        #{algorithm} AS fkalgorithm,
        par.pkalgparams AS fkalgparams
      FROM synthetic_network AS sn
      CROSS JOIN #{params_table} AS par
      EXCEPT
      SELECT fksynthetic_network, fkalgorithm, fkalgparams
      FROM clustering
      WHERE fkalgorithm = #{algorithm}
    EOT
    ]

    @db[:clustering].insert_multiple(dataset.all)
  end

  def prepare_clustering
    HASH_ALGORITHM_TO_TABLE.keys.each do |algorithm|
      prepare_clustering_for_algorithm(algorithm)
    end
  end

  def do_all_clustering
    HASH_ALGORITHM_TO_TABLE.keys.each do |algorithm|
      do_clustering(algorithm)
    end
  end

#  def do_clustering(algorithm)
#    table_alg = HASH_ALGORITHM_TO_TABLE[algorithm]
#    puts "do_clustering(#{table_alg})"
#    prepare_clustering
#    dataset = @db[:synthetic_network]
#              .inner_join(:clustering, :fksynthetic_network => :pksynthetic_network)
#              .inner_join(table_alg, :pkalgparams => :fkalgparams)
#              .filter(:fkalgorithm => algorithm, :clusteringmod => nil)
#
#    dataset.each do |row|
#      mod = case algorithm
#        when ALGORITHM_ACDC then Clusterer::acdc(row[:arc], row)
#        when ALGORITHM_HCAS then Clusterer::hcas(row[:arc], row)
#        else raise RuntimeError, "Unknown algorithm."
#        end
#      @db[:clustering].filter(:pkclustering => row[:pkclustering])
#          .update(:clusteringmod => mod)
#    end
#  end
  
  def do_clustering(algorithm)
    table_alg = HASH_ALGORITHM_TO_TABLE[algorithm]
    prepare_clustering

    while true
      row = @db[<<-EOT
      SELECT *
      FROM clustering c
      INNER JOIN synthetic_network sn ON sn.pksynthetic_network = c.fksynthetic_network
      INNER JOIN #{table_alg} par ON par.pkalgparams = c.fkalgparams
      WHERE c.fkalgorithm = #{algorithm}
      AND c.clusteringmod IS NULL
      AND c.pkclustering >= RANDOM() * (SELECT MAX(pkclustering) FROM clustering)
      LIMIT 1
      EOT
      ].all
      break if row.empty?
      row = row[0]

      mod = case algorithm
        when ALGORITHM_ACDC then Clusterer::acdc(row[:arc], row)
        when ALGORITHM_HCAS then Clusterer::hcas(row[:arc], row)
        else raise RuntimeError, "Unknown algorithm."
        end
      @db[:clustering].filter(:pkclustering => row[:pkclustering])
          .update(:clusteringmod => mod)
    end
  end

  def compute_mojos
    dataset = @db[:clustering]
        .inner_join(:synthetic_network, :pksynthetic_network => :fksynthetic_network)
        .filter(:mojo => nil)

    dataset.each do |row|
      reference = StringIO.new(row[:mod])
      found = StringIO.new(row[:clusteringmod])
      m = mojo(found, reference)
      @db[:clustering].filter(:pkclustering => row[:pkclustering])
          .update(:mojo => m)
    end
  end
end
