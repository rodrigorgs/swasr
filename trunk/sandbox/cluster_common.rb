require 'igraph'

def save_mod(clusters)
  clusters.each_with_index do |cluster, i|
    cluster.each { |v| puts "#{v} #{i}" }
  end
end
