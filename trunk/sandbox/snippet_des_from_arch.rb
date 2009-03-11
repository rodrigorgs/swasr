#!/usr/bin/env ruby

if __FILE__ == $0

require 'random_graphs'

def save_dot(fmt, dotfile, dot_graph)
  src = dotfile + ".dot"
  dot = dotfile + "." + fmt

  File.open(src, 'w') do |f|
    f << dot_graph.to_s << "\n"
  end

  system( "fdp -T#{fmt} #{src} -o #{dot}" )
  dot
end


alpha = 0.41
beta = 0.49
gamma = 0.10
#alpha = 0.33
#beta = 0.33
#gamma = 0.33
delta_in = 0
delta_out = 0


#10.times do |i|
#  puts i
#  arch = bollobas_game(10, alpha, beta, gamma, delta_in, delta_out)
#  design, modules = design_from_architecture(1000, arch, alpha, beta, gamma, delta_in, delta_out)
#  design.to_rsf("bollobas_arch_%02d.rsf" % i)
#end

arch = nil
design = nil
subgraphs = nil
modules = nil

10.times do |i|
  puts "== #{i}"
  arch = bollobas_game(10, alpha, beta, gamma, delta_in, delta_out)

  base_index = 0
  subgraphs = arch.vertices.map do
    n = (100 * (0.5 + rand) ** (-2)).to_i
    g = bollobas_game(n, alpha, beta, gamma, delta_in, delta_out, base_index)
    base_index += g.size
    g
  end

  size = subgraphs.inject(0) { |sum, g| sum + g.size }

  design = preferential_arch(size, arch, subgraphs)
  
  design.to_rsf("preferential_arch_%02d.rsf" % i)

#  modules = {}
#  subgraphs.each_with_index do |module_graph, i|
#    module_graph.each { |v| modules[v] = i }
#  end
#
#  arch_edges = design.edges.map { |e| [modules[e.source], modules[e.target]] }
#  arch_edges.uniq!
#  arch_edges.delete_if { |e| e[0] == e[1] }
#
#  puts "**** #{(arch_edges - arch.edges.map { |e| [e.source, e.target] }).inspect}"

#  p arch_edges

end


p modules

######################################################################
#
#dot = arch.to_dot_graph
#
#colors = %w(red blue yellow green orange purple cyan magenta cadetblue white)
#
#dot.each_element do |v| 
#  if v.kind_of? RGL::DOT::Node
#    v.options['color'] = colors[v.options['label'].to_i]
#  end
#end
#
#save_dot('png', 'arch', dot)
#
#Thread.new { `eog arch.png` }
#
#dot = design.to_dot_graph
#dot.each_element do |v|
#  if v.kind_of? RGL::DOT::Node
#    id = v.options['label'].to_i
#    #v.options['color'] = colors[modules[id]]
#    v.options['style'] = 'filled'
#    v.options['fillcolor'] = colors[modules[id]]
#    #v.options['label'] = modules[id].to_s
#  end
#end
#
#save_dot('png', 'design', dot)
#
#Thread.new { `eog design.png` }


end
