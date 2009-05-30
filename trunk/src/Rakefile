#!/usr/bin/env ruby

require 'rake'
require 'gxl'
require 'jars_as_modules'

NUMBERS_ARC = 'numbers.arc'
NUMBERS_MOD = 'numbers.mod'
NAMES_ARC = 'names.arc'
NAMES_MOD = 'names.mod'
DEPS = 'deps.xml'

task :extract => [DEPS, NAMES_ARC, NAMES_MOD]
task :default => [:stats, :distance_matrix]

desc "Extract dependencies using Dependency Finder"
task :depfind => DEPS

desc "Convert dependencies to pairs format"
task :pairs => [NAMES_ARC, NAMES_MOD]

desc "Create network with numbers as labels"
task :numbers

desc "Compute distance matrix"
task :distance_matrix

desc "Compute statistics"
task :stats

#directory 'jars'

file DEPS => 'jars' do
  system "DependencyExtractor -xml -out #{DEPS} jars"
end

file NAMES_ARC => DEPS do
  depxml_to_pairs2(DEPS, NAMES_ARC)
end

file NAMES_MOD => 'jars' do
  pairs = extract_modules(Dir.glob("jars/**/*.jar"))
  puts_pairs(pairs, NAMES_MOD)
end

#file NUMBERS_ARC => NUMBERS_MOD
#file NUMBERS_MOD do 
task :numbers do
  if !File.file?(NUMBERS_ARC) || !File.file?(NUMBERS_MOD)
    Rake::Task['pairs'].invoke # or .execute
    system "to_numeric_network.rb #{NAMES_ARC} #{NAMES_MOD} #{NUMBERS_ARC} #{NUMBERS_MOD}"
  end
end

task :analysis => :numbers do
  system "analysis.rb -e #{NUMBERS_ARC} -m #{NUMBERS_MOD} -v vertices.data -c clusters.data -g global.data"
end

task :stats => :analysis do
  system "stat_analysis.R vertices.data clusters.data global.data"
end

task :distance_matrix => :numbers do
  system "distances.R #{NUMBERS_ARC} distances-und.csv FALSE"
end

if __FILE__ == $0; system "rake --trace -f #{$0} #{ARGV.join(' ')}"; end
