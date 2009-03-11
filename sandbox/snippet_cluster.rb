require 'RAgglomerativeClusterer'
require 'random_graphs'
require 'view_matrix'

def fn_to_array(n, &block)
  array = Array.new(n) { Array.new(n) { 1.0 } }
  0.upto(n - 1) do |i|
    (i + 1).upto(n - 1) do |j|
      array[i][j] = array[j][i] = block.call(i, j)
    end
  end
  return array
end

def save_rsf(clustering, filename)
  File.open(filename, 'w') do |f|
    clustering.each_with_index do |cluster, i|
      cluster.each do |item|
        f.puts "contain C#{i} #{item}"
      end
    end
  end
end

if __FILE__ == $0

N = 100
modules = []
#func = "bollobas_game(N, 0.41, 0.49, 0.10, 0.24, 0.00)"
func = "bollobas_game(N, 0.31, 0.39, 0.30, 0.24, 0.00)"
modules << eval(func)
modules << eval(func)

n = 1 + modules[0].vertices.inject(0) { |max, v| v > max && v || max }

graph = two_layered_graph(modules[0], modules[1], N/10)
puts "#{graph.size}, n = #{n}"
vertices = graph.vertices.sort
depends = fn_to_array(graph.size) do |i, j|
  if graph.has_edge?(vertices[i], vertices[j]) then 1 else 0 end
end

view_matrix2(depends)

reference_clustering = [(0..n-1).to_a, (n..graph.size-1).to_a]

jaccard = fn_to_array(graph.size) do |i, j|
  jaccard_coefficient(depends[i], depends[j])
end

view_matrix2(jaccard)

dendogram = Dendogram.new agg_hier_cluster(graph.size, CompleteLinkage.new(TableSimilarity.new(jaccard)))

#h = dendogram.height - 1
clustering = dendogram.cut(0.90)
view = clustering.map { |cluster| cluster.map { |e| e < n && "A" || "B" }}
p view

save_rsf(reference_clustering, "a.rsf")
save_rsf(clustering, "b.rsf")
if `java MoJo a.rsf b.rsf` =~ /The Mojo value is (.+)/m
  puts "MoJo: #{$1}"
end

end
