#!/usr/bin/env ruby

if __FILE__ == $0

  require 'rubygems'
  require 'choice'
  require 'gxl'
  require 'graph'
  require 'random_graphs'

  Choice.options do
    option :input, :required => true do
      short '-i'
      long '--input=FILE'
      desc 'GXL file containing the architecture'
    end

    option :alpha, :required => true do
      short '-a'
      long '--alpha=PROBABILITY'
      cast Float
    end
    
    option :beta, :required => true do
      short '-b'
      long '--beta=PROBABILITY'
      cast Float
    end

    option :gamma, :required => true do
      short '-g'
      long '--gamma=PROBABILITY'
      cast Float
    end

    option :iterations do
      short '-n'
      long '--iterations=N'
      cast Integer
      default 1000
      desc 'Number of iterations'
    end

    option :din do
      long '--din=N'
      cast Integer
      default 0
      desc 'Delta in-degree'
    end

    option :dout do
      long '--dout=N'
      cast Integer
      default 0
      desc 'Delta out-degree'
    end

    option :output_l1 do
      short '-1'
      long '--output=FILE'
      desc 'Output filename l1'
    end
    
    option :output_l2 do
      short '-2'
      long '--output=FILE'
      desc 'Output filename'
    end
  end

  c = Choice.choices

  arch = nil
  begin
    arch_pairs = gxl_to_l1(c.input)
    arch = RGL::DirectedAdjacencyGraph[*arch_pairs.flatten]
  rescue Errno::ENOENT => e
    puts "File not found: #{c.input}"
  end

  arch.each_vertex { |v| puts v }

  g, modules = design_from_architecture(
     c.iterations, 
     arch,
     c.alpha,
     c.beta,
     c.gamma,
     c.din,
     c.dout)

  pairs = g.edges.map { |e| [e.source, e.target] }
  l1_to_gxl(pairs, c.output_l1)
  l2_to_gxl(modules, c.output_l2)
end
