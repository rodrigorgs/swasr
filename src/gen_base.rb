#!/usr/bin/env ruby

require 'random_graphs'
require 'fileutils'

class NetworkGenerator
  def read_params(file)
    return IO.readlines(file)[0].chomp.split("\t").map { |x| eval(x) }
  end

  def pinterval(from, to)
    from = 0.2 if from < 0
    return ((5 * from).to_i..((5 * to).to_i)).to_a.map { |x| x / 5.0 }
  end

  def n_params
    total = 0
    iterations { total += 1 }
    return total
  end

  def create_params(range=nil)
    total = 0
    iterations { total += 1 }
    puts "total: #{total}"

    pdircount = 0
    count = 0
    parent_dir = nil
    iterations do |args|
      if range.nil? || (count >= range.first && count <= range.last)
        if (count % 100 == 0)
          parent_dir = "%05d" % pdircount
          pdircount += 1
          puts "Creating parent dir #{parent_dir}"
          FileUtils.mkdir parent_dir unless File.exist?(parent_dir)
        end
        puts "#{count} #{args.join(",")}"
        dir = "#{parent_dir}/%08d" % count
        FileUtils.mkdir dir unless File.exists?(dir)
        File.open("#{dir}/model_params", "w") { |f| f.puts(args.join("\t")) }
      end
      count += 1
    end
  end

  #def iterations(&block)
  #end

  #def gen_net(args)
  #end

  def generate_networks(range=nil)
    files = Dir.glob("**/model_params").sort
    total = files.size

    old_cycle_time = Time.now
    start_time = Time.now

    count = 0
    count_nets_generated = 0
    files.each do |file|
      if range.nil? || (count >= range.first && count <= range.last)
        dir = File.dirname(file)
        puts dir
        if !File.exist?("#{dir}/numbers.arc")
          args = read_params(file)
          puts "  #{args.join(",")}"
          srand 0
          @dir = dir
          g = gen_net(args)
          #g.save2("#{dir}/numbers")
          count_nets_generated += 1
          #system "motifs.R #{dir}/numbers.arc #{dir}/motifs.data 3"
        else
          total -= 1
        end

        time_now = Time.now
        cycle_interval = time_now - old_cycle_time
        old_cycle_time = time_now

        count_interval = time_now - start_time
        total_interval = (count_interval * total) / count_nets_generated
        
        # interval  --  count
        # X         --  total
        puts "  This network: #{cycle_interval} seconds"
        puts "  Time remaining: #{(total_interval - count_interval) / 3600.00} hours"
      end 
      count += 1
    end
  end
end

class CgwGenerator < NetworkGenerator
  def e_values(p_value)
    p_value == 0.0 ? [0] : [1, 2, 4, 8]
  end

  def iterations(&block)
    n = 1000
    pinterval(-1, 1.0).each do |p1|
      pinterval(0.0, 1.0 - p1).each do |p2|
        pinterval(0.0, 1.0 - p1 - p2).each do |p3|
          p4 = 1.0 - p1 - p2 - p3
          e_values(p1).each do |e1|
            e_values(p2).each do |e2|
              e_values(p3).each do |e3|
                e_values(p4).each do |e4|
                  [-1, 0, 1, 10, 100, 1000].each do |alpha|
                    [2, 4, 8, 16, 32].each do |m|
                      block.call [n, p1, p2, p3, p4, e1, e2, e3, e4, alpha, m]
    end; end; end; end; end; end; end; end; end
  end
  
  def gen_net(args)
    g = gu_game(*args)
    g.save2("#{@dir}/numbers")
  end
end

class BcrGenerator < NetworkGenerator
  def iterations(&block)
    deltas = [0, 1, 2, 3, 4]
    probs = [0.0, 0.2, 0.4, 0.6]
    architectures = Dir.glob("architectures/*").sort.map { |x| "\"#{x}/arch-numbers\"" }
    n = 1000

    pinterval(0.0, 1.0).each do |alpha|
      pinterval(0.0, 1.0 - alpha).each do |beta|
        gamma = 1.0 - alpha - beta
        next if alpha + gamma < 0.01
        deltas.each do |delta_in|
          deltas.each do |delta_out|
            probs.each do |prob_out|
              architectures.each do |arch|
                block.call [n, arch, alpha, beta, gamma, delta_in, delta_out, prob_out]
    end; end; end; end; end; end
  end

  def gen_net(args)
    g = bcrplus_game(*args)
    g.save2("#{@dir}/numbers")
  end
end

class LfGenerator < NetworkGenerator
  def iterations(&block)
    # TODO: study parameters
    n = 1000
    on = 0
    om = 0

    # var  n mean   sd median trimmed mad min  max range skew kurtosis   se
    #   1 65 0.13 0.11   0.11    0.11 0.1   0 0.47  0.46  1.3     1.23 0.01
    mus = [0.0, 0.2, 0.4, 0.6]
    
    # var  n mean   sd median trimmed  mad  min  max range skew kurtosis   se
    #   1 65 2.69 0.22    2.7    2.68 0.22 2.18 3.35  1.17  0.3     0.18 0.03
    degseq_exps = [2.18, 2.7, 3.35]

    # var  n mean   sd median trimmed mad  min  max range skew kurtosis   se
    #   1 65 1.01 0.12   0.99       1 0.1 0.76 1.58  0.82  1.4     5.62 0.02
    size_exps = [0.76, 0.99, 1.58]

    ks = [5, 10, 15, 25]

    maxks = [58, 157, 482]

    # var  n  mean    sd median trimmed  mad min max range skew kurtosis  se
    #   1 65 23.48 52.37      6   10.49 7.41   1 303   302 3.76    14.92 6.5
    mincs = [1, 10, 273]

    #maxcs = [100, 200, 300]
    #maxcs = [nil]
    maxc = nil

    seed = 0

    ks.each do |k|
      maxks.each do |maxk|
        mus.each do |mu|
          degseq_exps.each do |t1|
            size_exps.each do |t2|
              mincs.each do |minc|
                block.call [n, k, maxk, mu, t1, t2, minc, maxc, seed]
    end; end; end; end; end; end
  end

  def gen_net(args)
    lf_game(*(args + ["#{@dir}/numbers"]))
  end
end

if __FILE__ == $0
  if ARGV[0].nil?
    puts "Parameters: (cgw|bcr|lf) (params|nets|total) [from to]"
    exit 1
  end

  model = ARGV[0]
  operation = ARGV[1]
  range = nil
  if !ARGV[2].nil? && !ARGV[3].nil?
    range = ARGV[2].to_i..ARGV[3].to_i  
  end

  generator = eval("#{model.capitalize}Generator").new
  case operation
  when 'params' then generator.create_params(range)
  when 'nets' then generator.generate_networks(range)
  when 'total' then puts generator.n_params
  else puts 'invalid operation'
  end
end

