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

def report(func)
  puts "#{eval(func)} #{func}"
end

if __FILE__ == $0
  while true
    report 'networks_to_synthesize'
    report 'decompositions_to_compute'
    report 'mojos_to_compute'
    report 'purities_to_compute'
    report 'decompositions_without_metrics'
    puts
    sleep 5
  end
end
