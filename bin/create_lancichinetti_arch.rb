#!/usr/bin/env ruby

if __FILE__ == $0

  require 'choice'
  require 'gxl'
  require 'graph'
  require 'tmpdir'
  require 'fileutils'

  Choice.options do
    header ''
    header 'Input/output:'
    
    option :output_l1, :required => true do
      short '-1'
      long '--output-l1=FILE'
      desc 'Output l1 filename (required)'
    end
    
    option :output_l2, :required => true do
      short '-2'
      long '--output-l2=FILE'
      desc 'Output l2 filename (required)'
    end

    option :statistics do
      long '--stats=FILE'
      desc 'Statistics: degree distribution, community'
      desc 'size distribution, distribution of the'
      desc 'mixing parameter (optional)'
    end

    separator ''
    separator 'Model parameters:'

    option :nodes do
      short '-n'
      long '--nodes=N'
      cast Integer
      default 1000
      desc 'Number of nodes (default 1000)'
    end

    option :avg_degree do
      short '-a'
      long '--avg-degree=N'
      cast Integer
      default 15
      desc 'Average degree (default 15)'
    end

    option :max_degree do
      short '-m'
      long '--max-degree=N'
      cast Integer
      default 50
      desc 'Maximum degree (default 50)'
    end

    option :exp_degree do
      short '-d'
      long '--exp-degree=N'
      cast Integer
      default 2
      desc 'Exponent for the degree distribution'
      desc '(default 2)'
    end

    option :exp_size do
      short '-s'
      long '--exp-size=N'
      cast Integer
      default 1
      desc 'Exponent for the community size'
      desc 'distribution (default 1)'
    end

    option :mixing do
      short '-p'
      long '--mixing=P'
      cast Float
      default 0.2
      desc 'Mixing parameter between 0.0 and 1.0'
      desc '(default 0.2)'
    end

    option :min_size do
      long '--min-size=N'
      cast Integer
      desc 'Minimum for the community sizes (optional)'
    end

    option :max_size do
      long '--max-size=N'
      cast Integer
      desc 'Maximum for the community sizes (optional)'
    end

    option :seed do
      long '--seed=N'
      cast Integer
      desc 'Seed for the random number generator'
      desc '(optional)'
    end

    footer ''
    footer 'Please refer to "Benchmark graphs for testing community detection algorithms",'
    footer 'by Lancichinetti et al (2008), for details.'
    footer ''
  end

  c = Choice.choices

  Dir.chdir(Dir.tmpdir) do
    File.open("bench_seed.dat", "w") { |f| f.puts c.seed } if c.seed
    File.open("parameters.dat", "w") do |f|
      f.puts c.nodes
      f.puts c.avg_degree
      f.puts c.max_degree
      f.puts c.exp_degree
      f.puts c.exp_size
      f.puts c.mixing
      f.puts c.min_size if c.min_size
      f.puts c.max_size if c.min_size && c.max_size
    end
    puts "Creating graph..."
    ret = `benchmark`
    puts ret
    exit 1 if ret =~ /ERROR/m
  end

  file_network = "#{Dir.tmpdir}/network.dat"
  file_community = "#{Dir.tmpdir}/community.dat"
  file_statistics = "#{Dir.tmpdir}/statistics.dat"

  if (File.file?(file_network) && File.file?(file_community) && 
      File.file?(file_statistics))
    puts IO.read(file_statistics)
    puts "Converting graph to gxl..."
    l1_to_gxl(read_pairs(file_network), c.output_l1)
    puts "Converting clusters to gxl..."
    l2_to_gxl(read_pairs(file_community), c.output_l2)
    puts "Cleaning up..."
    FileUtils.cp file_statistics, c.stats if c.stats
    FileUtils.rm_f [file_network, file_community, file_statistics]
  end
  puts "Done."
end
