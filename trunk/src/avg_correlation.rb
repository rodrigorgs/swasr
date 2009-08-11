#!/usr/bin/env ruby
require 'motif-compare'
require 'fileutils'

def read_motifs(filename)
  IO.readlines(filename).map { |x| x.to_f}
end

if __FILE__ == $0
  all_files = Dir.glob("../0*/**/motifs.data")
  java_files, other_files = all_files.partition { |x| x =~ /..\/01/ }

  all_files.sort!
  java_files.sort!
  other_files.sort!

  CUTOFF = 0.88

  java_motifs = java_files.map { |f| read_motifs f }
  other_motifs = other_files.map { |f| read_motifs f }
  all_motifs = all_files.map { |f| read_motifs f }

  all_files.size.times do |i|
    label = all_files[i].gsub(/\/motifs.data/, '').gsub(/\.\.\//, '')
    sum_correlation = 0.0
    java_files.size.times do |j|
      sum_correlation += correlation(all_motifs[i], java_motifs[j])
    end
    mean_correlation = sum_correlation / java_files.size
    printf "%s\t%.2f\t%s\n", (mean_correlation < CUTOFF ? "*" : " "), mean_correlation, label
  end
end
