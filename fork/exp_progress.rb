#!/usr/bin/env ruby
require 'exp_clust'

DB = ClusteringExperiment.new.db

def decompositions_to_compute
  DB['select count(*) from decomposition where mod is null'].first[:count]
end

def decompositions_without_metrics
  DB['select count(*) from decomposition where n_modules is null'].first[:count]
end

def networks_to_synthesize
  DB['select count(*) from network where arc is null'].first[:count]
end

def mojos_to_compute
  DB['select count(*) from decomposition where mojo is null and reference = false'].first[:count]
end

def purities_to_compute
  DB['select count(*) from decomposition where purity is null and reference = false'].first[:count]
end

def nmis_to_compute
  DB['select count(*) from decomposition where nmi is null and reference = false'].first[:count]
end

def base(table, column, where='1=1')
  DB["SELECT COUNT(*) FROM #{table} WHERE #{column} IS NULL AND (#{where})"].first[:count]
end

def report(func, *args)
  puts "#{send(func, *args)} #{func}(#{args.inspect})}"
end

if __FILE__ == $0
  while true
    #report 'networks_to_synthesize'
    #report 'decompositions_to_compute'
    #report 'mojos_to_compute'
    #report 'purities_to_compute'
    #report 'nmis_to_compute'
    #report 'decompositions_without_metrics'
    #report 'base', :network, :n_vertices
    #report 'base', :network, :sum_indegree
    report 'base', :triads, :triad1
    puts
    sleep 5
  end
end
