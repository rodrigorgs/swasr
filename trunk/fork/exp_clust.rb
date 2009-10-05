require 'rubygems'
require 'sequel' 
  # http://sequel.rubyforge.org/static/mwrc2009_presentation.html

require 'network_models'
require 'mojosim'
require 'clustering'

class Object # Sequel::Postgres::Dataset
  def random_row(table, column=nil)
    column = "pk_#{table}" if column.nil?

    val = self.and("#{column} >= RANDOM() * (SELECT MAX(pk_#{table}) FROM #{table})")
            .limit(1)
            .first
    if (val.nil? && self.count() > 0)
      val = self.first
    end

    return val
  end
end

class ClusteringExperiment
  attr_reader :db
  
  MODEL_BCR = 1
  MODEL_CGW = 2
  MODEL_LF = 3

  CLUSTERER_ACDC = 1
  CLUSTERER_HCAS = 2
  CLUSTERER_INFOMAP = 3
  CLUSTERER_BUNCH = 4

  CONFIG_SL75 = 1
  CONFIG_SL90 = 2
  CONFIG_CL75 = 3
  CONFIG_CL90 = 4
  CONFIG_ACDC = 5
  CONFIG_INFOMAP = 6
  CONFIG_BUNCH = 7

  CLASS_SOFTWARE = 1
  CLASS_WORD = 2

  def initialize
    #@db = Sequel.sqlite('teste.db')
    @db = Sequel.postgres('rodrigo', 
        :user => 'rodrigo', 
        :password => 'rodrigodb', 
        :host => 'mainha')
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

  def create_tables
    # read-only table
    @db.create_table? :clusterer_config do
      primary_key :pk_clusterer_config
      Integer :fk_clusterer

      String :nme_clusterer_config, :size => 10

        # HCAS
      String :linkage, :size => 1 # (C)omplete, (S)ingle
      String :coefficient, :size => 2 # aJ = Jaccard
      Float :cut_height
        # ACDC
      Boolean :top_level_clusters
      Integer :max_cluster_size
      String :patterns, :size => 4
    end

    # read-only table
    @db.create_table? :clusterer do
      primary_key :pk_clusterer
      String :nme_clusterer
    end

    @db.create_table? :decomposition do
      primary_key :pk_decomposition
      Boolean :reference   # is it a reference decomposition?
      Integer :fk_network
      Integer :fk_clusterer_config

      String :mod
      Integer :n_modules
      Integer :min_module_size
      Integer :max_module_size
      Integer :n_singletons
      Integer :n_subfive
      
      Integer :mojo
      
      index [:fk_network, :fk_clusterer_config], :unique => true
    end

    @db.create_table? :network do
      primary_key :pk_network
      String :nme_network
      Integer :fk_classification
      Integer :fk_model_config
      Boolean :synthetic

      String :arc
      Float :s_score
    end

    # read-only table
    @db.create_table? :classification do
      primary_key :pk_classification
      String :nme_classification
    end

    # read-only table
    @db.create_table? :model do
      primary_key :pk_model
      String :nme_model
    end

    @db.create_table? :model_config do
      primary_key :pk_model_config
      Integer :fk_model

      # All models
      Integer :seed, :default => 0
      Integer :n

      # CGW and BCR      
      Float :p1 # CGW, BCR
      Float :p2 # CGW, BCR
      Float :p3 # CGW, BCR

      # CGW only
      Float :p4
      Integer :e1
      Integer :e2
      Integer :e3
      Integer :e4
      Integer :m
      Float :alpha # CGW

      # BCR only
      Integer :fk_architecture
      Float :din
      Float :dout
      Float :mixing # BCR 

      # LR only
      Float :avgk
      Integer :maxk
      Float :mu
      Float :expdegree, :null => true
      Float :expsize, :null => true
      Integer :minm, :null => true
      Integer :maxm, :null => true
    end

    # read-only table
    @db.create_table? :architecture do
      primary_key :pk_architecture
      String :nme_architecture
      String :arc_architecture
      String :mod_architecture
    end

    @db.create_table? :triads do
      Integer :fk_network
      Float :triad1
      Float :triad2
      Float :triad3
      Float :triad4
      Float :triad5
      Float :triad6
      Float :triad7
      Float :triad8
      Float :triad9
      Float :triad10
      Float :triad11
      Float :triad12
      Float :triad13
    end
  end

  def create_initial_values
    ds = @db[:classification]
    ds.delete
    ds.insert(:pk_classification => CLASS_SOFTWARE, :nme_classification => 'software')
    ds.insert(:pk_classification => CLASS_WORD, :nme_classification => 'word adjacency')

    ds = @db[:clusterer]
    ds.delete
    ds.insert(:pk_clusterer => CLUSTERER_ACDC, :nme_clusterer => 'ACDC')
    ds.insert(:pk_clusterer => CLUSTERER_HCAS, :nme_clusterer => 'HCAS')
    ds.insert(:pk_clusterer => CLUSTERER_INFOMAP, :nme_clusterer => 'Infomap')
    ds.insert(:pk_clusterer => CLUSTERER_BUNCH, :nme_clusterer => 'Bunch')

    ds = @db[:clusterer_config]
    ds.delete
    ds.insert(:pk_clusterer_config => CONFIG_SL75, 
        :fk_clusterer => CLUSTERER_HCAS, :nme_clusterer_config => 'SL75',
        :linkage => 'S', :coefficient => 'aJ', :cut_height => 0.75)
    ds.insert(:pk_clusterer_config => CONFIG_SL90, 
        :fk_clusterer => CLUSTERER_HCAS, :nme_clusterer_config => 'SL90',
        :linkage => 'S', :coefficient => 'aJ', :cut_height => 0.90)
    ds.insert(:pk_clusterer_config => CONFIG_CL75, 
        :fk_clusterer => CLUSTERER_HCAS, :nme_clusterer_config => 'CL75',
        :linkage => 'C', :coefficient => 'aJ', :cut_height => 0.75)
    ds.insert(:pk_clusterer_config => CONFIG_CL90, 
        :fk_clusterer => CLUSTERER_HCAS, :nme_clusterer_config => 'CL90',
        :linkage => 'C', :coefficient => 'aJ', :cut_height => 0.90)
    ds.insert(:pk_clusterer_config => CONFIG_ACDC, 
        :fk_clusterer => CLUSTERER_ACDC, :nme_clusterer_config => 'ACDC',
        :top_level_clusters => true, :max_cluster_size => 99999, 
        :patterns => '+SO')
    ds.insert(:pk_clusterer_config => CONFIG_INFOMAP, 
        :fk_clusterer => CLUSTERER_INFOMAP, :nme_clusterer_config => 'Infomap')
    ds.insert(:pk_clusterer_config => CONFIG_BUNCH, 
        :fk_clusterer => CLUSTERER_BUNCH, :nme_clusterer_config => 'Bunch')

    ds = @db[:model]
    ds.delete
    ds.insert(:pk_model => MODEL_BCR, :nme_model => 'BCR+')
    ds.insert(:pk_model => MODEL_CGW, :nme_model => 'CGW')
    ds.insert(:pk_model => MODEL_LF,  :nme_model => 'LF')
  end

  def insert_safe(table, values)
    ret = false
      @db.transaction do
      dataset = @db[table].filter(values)
      count = dataset.count
      if count == 0
        @db[table].insert(values)
        ret = true
      elsif count > 1
        raise RuntimeError, 'More than 1 row returned.'
      end
    end

    return ret
  end

  def insert_safe_get_pk(table, values)
    insert_safe(table, values)
    pkcolumn = ('pk_' + table.to_s).to_sym
    return @db[table].filter(values).first[pkcolumn]
  end

  def insert_natural_network(name, arc, mod, classification)
    pk_network = insert_safe_get_pk :network, 
        :nme_network => name,
        :arc => arc,
        :fk_classification => classification,
        :synthetic => false

    insert_safe :decomposition,
        :fk_network => pk_network,
        :mod => mod, :reference => true
  end

  def insert_model_config(params)
    pk_model_config = insert_safe_get_pk :model_config, params
    insert_safe_get_pk :network, 
        :fk_model_config => pk_model_config,
        :synthetic => true
  end

  def generate_network(model, params)
    return (case model
    when MODEL_BCR then generate_bcrplus(params)
    when MODEL_CGW then generate_cgw(params)
    when MODEL_LF  then generate_lf(params)
    else raise RuntimeError, 'Invalid model'
    end)
  end
  

  def each_random_row(ds, table, column=nil, &block)
    while true
      row = ds.random_row(table, column)
      break if row.nil?
      block.call(row)
    end
  end

  def synthesize_network_from_db(row)
    g = generate_network(row[:fk_model], row)
    @db[:network].filter(:pk_network => row[:pk_network])
        .update(:arc => g[0])
    @db[:decomposition].filter(:fk_network => row[:pk_network],
        :reference => true)
        .update(:mod => g[1])
  end

  def generate_missing_networks
    ds = @db[:network]
            .inner_join(:model_config, :pk_model_config => :fk_model_config)
            .left_outer_join(:architecture, :pk_architecture => :fk_architecture)
            .filter(:arc => nil, :synthetic => true)

    each_random_row(ds, :network) do |row|
      synthesize_network_from_db(row)
    end
  end

  def compute_decomposition_metrics(row)
    raise RuntimeError, "Empty mod, pk_decomposition =  #{row[:pk_decomposition]}" if row[:mod].nil? || row[:mod].strip.size == 0

    LOG.info("compute decomposition for pk #{row[:pk_decomposition]}")

    pairs = int_pairs_from_string(row[:mod])  
    gr = pairs.group_by { |x| x[1] }
    module_sizes = gr.values.map { |x| x.size }
    
    row[:n_modules] = module_sizes.size if row[:n_modules].nil?
    row[:min_module_size] = module_sizes.min if row[:min_module_size].nil?
    row[:max_module_size] = module_sizes.max if row[:max_module_size].nil?
    row[:n_singletons] = module_sizes.count { |x| x == 1 } if row[:n_singletons].nil?
    row[:n_subfive] = module_sizes.count { |x| x <= 1 } if row[:n_subfive].nil?

    @db[:decomposition].filter(:pk_decomposition => row[:pk_decomposition])
        .update(row)
  end

  def compute_missing_decomposition_metrics
    ds = @db[:decomposition]
        .filter(<<-EOT
        mod IS NOT NULL AND (
          n_modules is null
          or min_module_size is null
          or max_module_size is null
          or n_singletons is null
          or n_subfive is null
        )
        EOT
        )
        #.filter(:n_modules => nil)
        #.or(:min_module_size => nil)
        #.or(:max_module_size => nil)
        #.or(:n_singletons => nil)
        #.or(:n_subfive => nil)
    #puts ds.count

    each_random_row(ds, :decomposition) do |row|
      compute_decomposition_metrics(row)
    end
  end

  def insert_stub_decompositions
    insert_stub_reference_decompositions

    @db.transaction do
      ds = @db[<<-EOT
        SELECT net.pk_network AS fk_network, 
            cconf.pk_clusterer_config AS fk_clusterer_config,
            FALSE as reference
        FROM network AS net
        CROSS JOIN clusterer_config AS cconf
       EXCEPT
        SELECT fk_network, fk_clusterer_config, FALSE as reference
        FROM decomposition
      EOT
      ]
      
      @db[:decomposition].insert_multiple(ds.all)
    end
  end

  def insert_stub_reference_decompositions
    @db.transaction do
      ds = @db[<<-EOT
        SELECT pk_network AS fk_network
        FROM network
       EXCEPT
        SELECT fk_network
        FROM decomposition
        WHERE reference = true
      EOT
      ]

      rows = ds.all.map { |x| x.merge({:reference => true}) }
      @db[:decomposition].insert_multiple(rows)
    end
  end

    #insert_safe :decomposition, :reference => true,
    #    :fk_network => row[:pk_network],
    #    :mod => g[1]

  def compute_decomposition(row)
    n = row[:arc] && row[:arc].size || 'nil'
    LOG.info "compute_decomposition: #{n} arcs"
    mod = case row[:fk_clusterer]
      when CLUSTERER_ACDC then Clusterer::acdc(row[:arc], row)
      when CLUSTERER_HCAS then Clusterer::hcas(row[:arc], row)
      when CLUSTERER_INFOMAP then Clusterer::infomap(row[:arc], row)
      else raise RuntimeError, "Unknown algorithm."
      end
    @db[:decomposition].filter(:pk_decomposition => row[:pk_decomposition])
        .update(:mod => mod)
  end
  
  def compute_missing_decompositions
    insert_stub_decompositions

    ds = @db[:decomposition]
        .inner_join(:clusterer_config, :pk_clusterer_config => :fk_clusterer_config)
        .inner_join(:network, :pk_network => :decomposition__fk_network)
        .filter(:mod => nil).and('arc IS NOT NULL')
        .and(:synthetic => true)

    each_random_row(ds, :decomposition) do |row|
      compute_decomposition(row)
    end
  end
  
  def compute_mojo(row)
    if (row[:mod].nil? || row[:mod].strip.size == 0)
      raise RuntimeError, "Found decomposition is empty for pk #{pk_decomposition}"
    end
    if (row[:reference_mod].nil? || row[:reference_mod].strip.size == 0)
      raise RuntimeError, "Reference decomposition is empty for pk #{pk_decomposition}"
    end
    reference = StringIO.new(row[:reference_mod])
    found = StringIO.new(row[:mod])
    m = mojo(found, reference)
    @db[:decomposition].filter(:pk_decomposition => row[:pk_decomposition])
        .update(:mojo => m)
  end

  # TODO works only when executed multiple times (why?)
  def compute_missing_mojos
    ds = @db[:decomposition.as(:dec)]
          .inner_join(:decomposition.as(:ref), :fk_network => :fk_network)
          .inner_join(:network, :pk_network => :fk_network)
          .filter(:dec__mojo => nil, :ref__reference => true)
          .and("dec.mod IS NOT NULL")
          .and("ref.mod IS NOT NULL")
          .and(:synthetic => true)
          .select(:dec__pk_decomposition.as(:pk_decomposition), 
              :ref__pk_decomposition.as(:pk_ref), 
              :dec__mod, 
              :ref__mod.as(:reference_mod))

    each_random_row(ds, :decomposition, 'dec.pk_decomposition') do |row|
      puts "mojo #{row[:pk_decomposition]} #{row[:pk_ref]}"
      compute_mojo(row)
    end
  end
end

CE = ClusteringExperiment

def insert_model_params(exp)
  puts 'bcr'
  arch_id = exp.db[:architecture].filter(:nme_architecture => '16-findbugs').first[:pk_architecture]
  0.upto(99) do |seed|
  [0.00, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60].each do |mu|
  exp.insert_model_config :fk_model => ClusteringExperiment::MODEL_BCR,
      :seed => seed,
      :n => 1000,
      :fk_architecture => arch_id,
      :p1 => 0.7,
      :p2 => 0.2,
      :p3 => 0.1,
      :din => 0,
      :dout => 0,
      :mu => mu
  end
  end

  puts 'lf'
  0.upto(99) do |seed|
  [0.00, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80].each do |mixing|
  exp.insert_model_config :fk_model => ClusteringExperiment::MODEL_LF,
      :seed => seed, 
      :n => 1000, 
      :avgk => 15, 
      :maxk => 482, 
      :mixing => mixing,
      :expdegree => 2.18,
      :expsize => 1.0,
      :minm => 5,
      :maxm => nil
  end
  end

  puts 'cgw'
  0.upto(99) do |seed|
  [-1, 0, 1, 10, 100, 1000].each do |alpha|
  exp.insert_model_config :fk_model => ClusteringExperiment::MODEL_CGW, 
    :seed => seed,
    :p1 => 0.6,
    :p2 => 0.2,
    :p3 => 0.0,
    :p4 => 0.2,
    :e1 => 4,
    :e2 => 1,
    :e3 => 0,
    :e4 => 1,
    :n => 1000,
    :m => 16,
    :alpha => alpha
  end
  end    
end

if __FILE__ == $0
  exp = ClusteringExperiment.new
  #exp.drop_all_tables
  exp.create_tables
  exp.create_initial_values

  #insert_model_params(exp)
  exp.insert_stub_decompositions
  puts '## Now you can start this script in another network node ##'
  exp.generate_missing_networks
  exp.compute_missing_decompositions
  exp.compute_missing_decomposition_metrics
  exp.compute_missing_mojos
end

