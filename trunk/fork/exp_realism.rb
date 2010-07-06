#!/usr/bin/env ruby

require 'exp_clust'
require 'network_models'
require 'fileutils'

def pinterval(from, to)
  from = 0.2 if from < 0
  return ((5 * from).to_i..((5 * to).to_i)).to_a.map { |x| x / 5.0 }
end

def n_params
  total = 0
  iterations { total += 1 }
  return total
end

def e_values(p_value)
  p_value == 0.0 ? [0] : [1, 2, 4, 8]
end

def cgw_iterations(&block)
  n = 1000
  pinterval(-1, 1.0).each do |p1|
    pinterval(0.0, 1.0 - p1).each do |p2|
      pinterval(0.0, 1.0 - p1 - p2).each do |p3|
        p4 = 1.0 - p1 - p2 - p3
        p4 = 0.0 if p4 < 0.001
        e_values(p1).each do |e1|
          e_values(p2).each do |e2|
            e_values(p3).each do |e3|
              e_values(p4).each do |e4|
                next if 2*p4*e4 >= p1*e1 + p2*e2
                [-1, 0, 1, 10, 100, 1000].each do |alpha|
                  [2, 4, 8, 16, 32].each do |m|
                    block.call [n, p1, p2, p3, p4, e1, e2, e3, e4, alpha, m]
  end; end; end; end; end; end; end; end; end
end

def bcr_iterations(architectures, &block)
  deltas = [0, 1, 2, 3, 4]
  probs = [0.0, 0.2, 0.4, 0.6]
  #architectures = Dir.glob("architectures/*").sort.map { |x| "\"#{x}/arch-numbers\"" }
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

def er_iterations(&block)
  n = 1000
  sm = (2000..10000).select { |x| x % 100 == 0 }
  sdirected = [false, true]
  sseed = 0..19

  sseed.each do |seed|
    sdirected.each do |directed|
      sm.each do |m|
        block.call(n, m, directed, seed)
      end
    end
  end
end

def ba_iterations(&block)
  n = 1000
  sm = 2..10
  sseed = 0..19

  sseed.each do |seed|
    [true, false].each do |directed|
      soutpref = directed == true ? [true, false] : [true]
      soutpref.each do |outpref|
        sm.each do |m|
          block.call(n, m, directed, outpref, seed)
        end
      end
    end
  end
end

def lf_iterations(&block)
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

if __FILE__ == $0
  exp = ClusteringExperiment.new

  #puts 'bcr'
  #archs = exp.db[:architecture].all

  #bcr_iterations(archs) do |n, arch, alpha, beta, gamma, delta_in, delta_out, prob_out|
  #  params = { 
  #      :fk_model => ClusteringExperiment::MODEL_BCR,
  #      :seed => 0,
  #      :n => 1000,
  #      :fk_architecture => arch[:pk_architecture],
  #      :p1 => alpha,
  #      :p2 => gamma,
  #      :p3 => beta,
  #      :din => delta_in,
  #      :dout => delta_out,
  #      :mu => prob_out}
  #  pk_model_config = exp.insert_model_config params
  #  exp.insert_safe :experiment_model_config, {:fk_experiment => 1, :fk_model_config => pk_model_config}
  #end

  #i = 0
  #ba_iterations do |n, m, directed, outpref, seed|
  #  params = {:fk_model => ClusteringExperiment::MODEL_BA,
  #     :n => n, :m => m, :directed => directed, :outpref => outpref, :seed => seed}
  #  pk_model_config = exp.insert_model_config params
  #  exp.insert_safe :experiment_model_config, {:fk_experiment => 5, :fk_model_config => pk_model_config}
  #  i +=1
  #end
  #p i

  i = 0
  er_iterations do |n, m, directed, seed|
    params = {:fk_model => ClusteringExperiment::MODEL_ER,
       :n => n, :m => m, :directed => directed, :seed => seed}
    pk_model_config = exp.insert_model_config params
    exp.insert_safe :experiment_model_config, {:fk_experiment => 5, :fk_model_config => pk_model_config}
    i +=1
  end
  p i



  #lf_iterations do |n, k, maxk, mu, t1, t2, minc, maxc, seed|
  #  params = {
  #    :fk_model => ClusteringExperiment::MODEL_LF,
  #    :seed => seed,
  #    :n => 1000,
  #    :avgk => k,
  #    :maxk => maxk,
  #    :mixing => mu,
  #    :expdegree => t1,
  #    :expsize => t2,
  #    :minm => minc,
  #    :maxm => maxc}

  #  pk_model_config = exp.insert_model_config params
  #  exp.insert_safe :experiment_model_config, {:fk_experiment => 1, :fk_model_config => pk_model_config}
  #end

  #cgw_iterations do |n, p1, p2, p3, p4, e1, e2, e3, e4, alpha, m|
  #  params = {
  #    :fk_model => ClusteringExperiment::MODEL_CGW,
  #    :seed => 0,
  #    :p1 => p1,
  #    :p2 => p2,
  #    :p3 => p3,
  #    :p4 => p4,
  #    :e1 => e1,
  #    :e2 => e2,
  #    :e3 => e3,
  #    :e4 => e4,
  #    :n => 1000,
  #    :m => m,
  #    :alpha => alpha}
  #  
  #  pk_model_config = exp.insert_model_config params
  #  exp.insert_safe :experiment_model_config, {:fk_experiment => 1, :fk_model_config => pk_model_config}
  #end

end

