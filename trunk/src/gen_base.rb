#!/usr/bin/env ruby

require 'random_graphs'
require 'fileutils'

class NetworkGenerator
  def read_params(file)
    return IO.readlines(file)[0].chomp.split("\t").map { |x| eval(x) }
  end

  def pinterval(from, to)
    from = 0.2 if from < 0
    return (5 * from).to_i.upto((5 * to).to_i).to_a.map { |x| x / 5.0 }
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
    time_start = Time.now

    count = 0
    files.each do |file|
      if range.nil? || (count >= range.first && count <= range.last)
        dir = File.dirname(file)
        puts dir
        if !File.exists?("#{dir}/numbers.arc")
          args = read_params(file)
          puts "  #{args.join(",")}"
          srand 0
          g = gen_net(args)
          g.save2("#{dir}/numbers")
          #system "motifs.R #{dir}/numbers.arc #{dir}/motifs.data 3"
        else
          total -= 1
        end
        interval = (Time.now - time_start)
        puts interval
        # interval  --  count
        # X         --  total
        remaining = (interval * total) / count # seconds
        puts "Time remaining: #{remaining / 3600.0} hours"
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
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  
  def gen_net(args)
    gu_game(*args)
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
        deltas.each do |delta_in|
          deltas.each do |delta_out|
            probs.each do |prob_out|
              architectures.each do |arch|
                block.call [n, arch, alpha, beta, gamma, delta_in, delta_out, prob_out]
              end
            end
          end
        end
      end
    end
  end

  def gen_net(args)
    bcrplus_game(*args)
  end
end

def main
  # model op from to
end

if __FILE__ == $0
  if ARGV[0].nil?
    puts "Parameters: (cgw|bcr) (params|nets|total) [from to]"
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

