require 'grok'
require 'set'

def is_util(id)
  return !id.include?('CH.ifa.draw')
end

def get_cluster(id)
  if id =~ /CH\.ifa\.draw\.(.+?)\./
    return 'jhotdraw.' + $1
  else
    return id[0..(id.rindex('.')-1)]
  end
end

def stats(clusters_in_or_out, is_out=true)
  clusters_in_or_out.each_pair do |cluster, edges|
    if !is_out then edges = edges.map{|a, b| [b, a]} end
    all = edges.map { |a, b| a }.uniq
    traders = Set.new
    edges.each do |from, to|
      if get_cluster(to) != cluster
        traders << from
      end
    end
    puts "%03.2f\t#{cluster}\t#{all.size}" % (100 * traders.size.to_f / all.size)
  end
end

l1 = read_rsf_pairs('../corpora/jhotdraw/whole/classes.rsf').select { |a, b| !is_util(a) && !is_util(b) }
l2 = l1.map { |a, b| [get_cluster(a), get_cluster(b)] }.uniq
clusters_out = l1.group_by { |a, b| get_cluster(a) }
clusters_in = l1.group_by { |a, b| get_cluster(b) }

puts "============== Clusters OUT ==============="
puts "Porcentagem das classes de cada cluster que possuem arestas para classes de outro cluster"
puts
stats(clusters_out)

puts
puts "============== Clusters IN ==============="
puts "Porcentagem das classes de cada cluster que possuem arestas vindas classes de outro cluster\n"
puts
stats(clusters_in, false)
