#!/usr/bin/env ruby

if __FILE__ == $0

  require 'choice'
  require 'gxl'
  require 'graph'
  require 'random_graphs'

  Choice.options do
    header ''
    header 'Input/output:'

    option :input, :required => true do
      short '-i'
      long '--input=FILE'
      desc 'File containing the architecture'
      desc '(required)'
    end
    
    option :output_l1, :required => true do
      short '-1'
      long '--output=FILE'
      desc 'Output l1 filename (required)'
    end
    
    option :output_l2, :required => true do
      short '-2'
      long '--output=FILE'
      desc 'Output l2 filename (required)'
    end

    option :format do
      short '-f'
      long '--format=(gxl|pairs)'
      default 'gxl'
      valid %w(gxl pairs)
      desc 'File format used for input and output'
      desc '(default: gxl)'
    end

    separator ''
    separator 'Model parameters:'

    option :nodes do
      short '-n'
      long '--nodes=N'
      cast Integer
      default 1000
      desc 'Number of nodes (default: 1000)'
    end

    option :alpha do
      short '-a'
      long '--alpha=P'
      cast Float
      default 0.41
      desc 'Probability of adding a vertex with an'
      desc 'outgoing edge (default: 0.41)'
    end
    
    option :beta do
      short '-b'
      long '--beta=P'
      cast Float
      default 0.49
      desc 'Probability of adding an edge between'
      desc 'vertices from distinct modules'
      desc '(default: 0.49)'
    end

    option :gamma do
      short '-g'
      long '--gamma=P'
      cast Float
      default 0.10
      desc 'Probability of adding a vertex with an'
      desc 'ingoing edge (default: 0.10)'
    end

    option :din do
      long '--din=N'
      cast Float
      default 0.0
      desc 'In-degree offset (default: 0.0)'
    end

    option :dout do
      long '--dout=N'
      cast Float
      default 0.0
      desc 'Out-degree offset (default: 0.0)'
    end

    separator ''
  end

  c = Choice.choices

  arch = nil
  begin
    arch_pairs = (c.format == 'gxl') ? gxl_to_l1(c.input) : read_pairs(c.input)
    #arch = RGL::DirectedAdjacencyGraph[*arch_pairs.flatten]
    arch = Network.new
    arch.add_edges(arch_pairs)
  rescue Errno::ENOENT => e
    puts "File not found: #{c.input}"
    exit 1
  end

  g = rodrigo2008_game(
     c.nodes, 
     arch,
     c.alpha,
     c.beta,
     c.gamma,
     c.din,
     c.dout)

  pairs = g.edges.map { |e| [e.from.eid, e.to.eid] }
  modules = g.nodes.map { |n| [n.eid, n.cluster.eid] }
  if c.format == 'gxl'
    l1_to_gxl(pairs, c.output_l1)
    l2_to_gxl(modules, c.output_l2)
  elsif c.format == 'pairs'
    puts_pairs(pairs, c.output_l1)
    puts_pairs(modules, c.output_l2)
  end
end
