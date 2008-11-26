require 'grok'
require 'graph'

a, b = 10, 13

g1 = DegreesDAG[*read_rsf_pairs(`ls ../corpora/junit_versions/#{'%02d' % a}*`.chomp).flatten]
g2 = DegreesDAG[*read_rsf_pairs(`ls ../corpora/junit_versions/#{'%02d' % b}*`.chomp).flatten]

x = []
y = []
diff = (g2.edges - g1.edges).select { |e| g1.has_vertex?(e.target) && !g1.has_vertex?(e.source) }
puts "Arestas saindo de vertices novos: #{diff.size}"
diff.each do |edge|
  u, v = edge.source, edge.target 
  if g1.has_vertex?(v) && !g1.has_vertex?(u)
    x << g1.out_degree(v)
    y << g1.in_degree(v)
    #puts "#{g1.in_degree(v)} #{g1.out_degree(v)}"
  end
end

require 'rsruby'

RSRuby.instance.plot(x, y, :xlab => 'out degree', :ylab => 'in degree')

print 'Pressione qualquer tecla para finalizar...'
gets
