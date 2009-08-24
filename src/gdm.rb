require 'grok'

# GdeM: File format used by Nicolas Anquetil
# Input: pairs of sequential numbers starting from 0.
def arc_to_gdm(pairs)
  pairs = read_pairs(pairs) if pairs.kind_of?(String)
  pairs.map! { |a, b| [a.to_i, b.to_i] }
  nodes = entities(pairs).sort
  
  #group = pairs.group_by { |from, to| cluster }

  nodes.each do |node|
    line = [0] * nodes.size
    #group[node].each { |_,b| line[b] = 1 }
    pairs.each do |a, b| 
      line[b] = 1 if a == node
      line[a] = 1 if b == node
    end
    puts "#{node} " + line.join(' ')
  end
end

def gdm_clusters_to_mod(input_file)
  IO.foreach(input_file) do |line|
    if line =~ /^couple\((\d+),\[(.+?)\]/
      mod = $1
      $2.split(",").each do |node|
        puts "#{node} #{mod}"
      end
    end
  end
end

def cluster_anquetil(params, prune_height, input, output=nil)
  system "ruby -r gdm -e 'arc_to_gdm \"#{input}\"' | prelude | cluster #{params} | prune -s#{prune_height} > tmp"
  gdm_clusters_to_mod('tmp')
end
