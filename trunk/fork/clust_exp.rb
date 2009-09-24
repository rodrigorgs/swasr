require 'rubygems'
require 'sequel' 
  # http://sequel.rubyforge.org/static/mwrc2009_presentation.html

class ClusteringExperiment
  MODEL_BCR = 0
  MODEL_CGW = 1
  MODEL_LF = 2

  HASH_MODEL_TO_TABLE = {
    MODEL_BCR => :bcr_params, 
    MODEL_CGW => :cgw_params,
    MODEL_LF => :lf_params}

  attr_reader :db

  def initialize
    @db = Sequel.sqlite('teste.db')
  end

  def create_tables
    @db.create_table? :synthetic_network do
      primary_key :id
      Integer :fkmodel
      Integer :fkparams
      String :arc
      String :mod
    end

    @db.create_table? :cgw_params do
      primary_key :id
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
      primary_key :id
      Integer :seed
      Integer :fkarchitecture
      Float :p1
      Float :p2
      Float :p3
      Float :din
      Float :dout
      Float :mu
    end

    @db.create_table? :lf_params do
      primary_key :id
      Integer :n
      Float :avgk
      Integer :maxk
      Float :mixing
        # parameters below are optional
      Integer :seed
      Float :expdegree
      Float :expsize
      Integer :minm
      Integer :maxm
    end

    @db.create_table? :architecture do
      primary_key :id
      String :arch_name
      String :arch_arc
      String :arch_mod
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
    id = @db[table].filter(params).first[:id]
    insert_safe :synthetic_network, :fkmodel => model, :fkparams => id
  end
end

if __FILE__ == $0
  exp = ClusteringExperiment.new
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
    exp.db[:architecture].insert(:arch_name => 'dummy', :arch_arc => '', :arch_mod => '')
  end
  arch_id = exp.db[:architecture].first[:id]

  p exp.insert_synthetic_network_params(ClusteringExperiment::MODEL_BCR,
      :seed => 0,
      :fkarchitecture => arch_id,
      :p1 => 0.7,
      :p2 => 0.2,
      :p3 => 0.1,
      :din => 2,
      :dout => 3,
      :mu => 0.3)

  p exp.db[:synthetic_network].filter(:fkmodel => ClusteringExperiment::MODEL_BCR).inner_join(:bcr_params, :id => :fkparams)
    .inner_join(:architecture, :id => :fkarchitecture)
    .all

end
