#!/usr/bin/env ruby
require 'exp_clust'

DB = ClusteringExperiment.new.db
$times = Hash.new([])

#def decompositions_to_compute
#  DB['select count(*) from decomposition where mod is null'].first[:count]
#end
#
#def decompositions_without_metrics
#  DB['select count(*) from decomposition where n_modules is null'].first[:count]
#end
#
#def networks_to_synthesize
#  DB['select count(*) from network where arc is null'].first[:count]
#end
#
#def mojos_to_compute
#  DB['select count(*) from decomposition where mojo is null and reference = false'].first[:count]
#end
#
#def purities_to_compute
#  DB['select count(*) from decomposition where purity is null and reference = false'].first[:count]
#end
#
#def nmis_to_compute
#  DB['select count(*) from decomposition where nmi is null and reference = false'].first[:count]
#end

def base(table, column, where='1=1')
  count = DB["SELECT COUNT(*) FROM #{table} WHERE #{column} IS NULL AND (#{where})"].first[:count]
  $times[[table, column]] << [Time.now, count]
  t = $times[[table, column]]

  vel = 0
  time_remaining = 0
  interval = [10, t.size].min
  if t.size >= 2
    t0 = t[-interval]
    t1 = t[-1]
    vel = ((t1[1] - t0[1]).to_f / (t1[0] - t0[0]).to_f).abs
    time_remaining = count / vel
  end

  puts "#{count} #{table}.#{column}, vel = %.2f, remaining: #{Time.at(time_remaining).gmtime.strftime('%R:%S')}" % [vel]

Time.at(7683).gmtime.strftime('%R:%S')


  return count
end

#def report(func, *args)
#  puts "#{send(func, *args)} #{func}(#{args.inspect})}"
#end

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
    #report 'base', :triads, :triad1
    #report 'base', :network, :arc
    base(:network, :arc)
    puts
    sleep 5
  end
end
