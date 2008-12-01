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

colors = %w(red blue yellow green orange purple black gray)

#alpha = 0.41
#beta = 0.49
#gamma = 0.10
alpha = 0.33
beta = 0.33
gamma = 0.33
delta_in = 0
delta_out = 0

#arch = bollobas_game(10, alpha, beta, gamma, delta_in, delta_out)
arch = DegreesDAG.new
arch.add_edge(0,1)
dot = arch.to_dot_graph

dot.each_element do |v| 
  if v.kind_of? RGL::DOT::Node
    v.options['color'] = colors[v.options['label'].to_i]
  end
end

#dot.each_element { |v| p v.options }

save_dot('png', 'arch', dot)

Thread.new { `eog arch.png` }


design, modules = design_from_architecture(300, arch, alpha, beta, gamma, delta_in, delta_out)

dot = design.to_dot_graph
dot.each_element do |v|
  if v.kind_of? RGL::DOT::Node
    id = v.options['label'].to_i
    #v.options['color'] = colors[modules[id]]
    v.options['style'] = 'filled'
    v.options['fillcolor'] = colors[modules[id]]
    #v.options['label'] = modules[id].to_s
  end
end

save_dot('png', 'design', dot)

Thread.new { `eog design.png` }

