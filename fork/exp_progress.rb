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
    time_remaining = count / vel if (vel > 0)
  end

  puts "#{count} #{table}.#{column}, vel = %.2f, remaining: #{Time.at(time_remaining).gmtime.strftime('%U dias %R:%S')}" % [vel]

Time.at(7683).gmtime.strftime('%R:%S')


  return count
end

#def report(func, *args)
#  puts "#{send(func, *args)} #{func}(#{args.inspect})}"
#end

if __FILE__ == $0
  where = 'fk_dataset = 1 AND s_score >= 0.88 AND ref_n_external_edges <= 0.5 * n_edges AND n_vertices = 1000'
  while true
    #base(:network, :arc)
    #base(:decomposition, :mod)
    #base(:triads, :triad1)
    #base(:network, :s_score)
    #base(:view_decomposition, :mod, where)
    base(:view_decomposition, :mojo, where)
    puts
    sleep 5
  end
end
