#!/usr/bin/env ruby

require 'rake'
require 'gxl'

NUMBERS_ARC = 'numbers.arc'
NUMBERS_MOD = 'numbers.mod'
NAMES_ARC = 'names.arc'
NAMES_MOD = 'names.mod'
DEPS = 'deps.xml.gz'
ARCH_NAMES_ARC = 'arch-names.arc'
ARCH_NAMES_MOD = 'arch-names.mod'
ARCH_NUMBERS_ARC = 'arch-numbers.arc'
ARCH_NUMBERS_MOD = 'arch-numbers.mod'

task :extract => [DEPS, NAMES_ARC, NAMES_MOD]
task :default => [:stats, :distance_matrix, :motifs]

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

desc "Compute L2 architecture"
task :arch_names

desc "Compute L2 architecture (numbers)"
task :arch_numbers => ARCH_NUMBERS_ARC

desc "Find vertices associated to more than one module"
task :duplicates => 'duplicates.txt'

desc "Motifs"
task :motifs => 'motifs.data' 
task :motifs4 => 'motifs4.data'

#directory 'jars'

file 'duplicates.txt' => 'names.mod' do
  system "duplicates.rb names.mod > duplicates.txt"
end

task :arch_names => "arch-names.png"

file ARCH_NAMES_ARC => ARCH_NAMES_MOD
file ARCH_NAMES_MOD => [NAMES_ARC, NAMES_MOD] do
  g = Network.new NAMES_ARC, NAMES_MOD
  arch = g.lift
  arch.save2("arch-names")
end

file ARCH_NUMBERS_ARC => ARCH_NUMBERS_MOD
file ARCH_NUMBERS_MOD => [NUMBERS_ARC, NUMBERS_MOD] do
  g = Network.new NUMBERS_ARC, NUMBERS_MOD
  arch = g.lift
  arch.save2("arch-numbers")
end

file "arch-names.png" => "arch-names.dot" do
  system "dot -Tpng arch-names.dot -o arch-names.png"
end

file "arch-names.dot" => "arch-names.arc" do
  g = Network.new "arch-names.arc", "arch-names.mod"
  g.save_dot "arch-names.dot"
end

file DEPS => 'jars' do
  system "DependencyExtractor -xml jars | gzip > #{DEPS}"
end

file NAMES_ARC => DEPS do
  depxml_to_pairs2(DEPS, NAMES_ARC)
end

file NAMES_MOD => 'jars' do
  system "ClassFinder -compact jars/ | sed -e 's/: jars\\// /g' > #{NAMES_MOD}"
  #pairs = extract_modules(Dir.glob("jars/**/*.jar"))
  #puts_pairs(pairs, NAMES_MOD)
end

#file NUMBERS_ARC => NUMBERS_MOD
#file NUMBERS_MOD do 
task :numbers do |t|
  if !File.file?(NUMBERS_ARC) || !File.file?(NUMBERS_MOD)
    Rake::Task['pairs'].invoke # or .execute
    system "to_numeric_network.rb #{NAMES_ARC} #{NAMES_MOD} #{NUMBERS_ARC} #{NUMBERS_MOD}"
  else
    class << t
      def needed?
        false
      end
    end
  end
end

task :analysis => :numbers do
  system "analysis.rb -e #{NUMBERS_ARC} -m #{NUMBERS_MOD} -v vertices.data -c clusters.data -g global.data"
end

task :stats => :analysis do
  system "stat_analysis.R vertices.data clusters.data global.data"
end

task :distance_matrix => ['distances-und.csv', 'distances-dir.csv']

file 'distances-und.csv' => :numbers do
  system "distances.R #{NUMBERS_ARC} distances-und.csv FALSE"
end

file 'distances-dir.csv' => :numbers do
  system "distances.R #{NUMBERS_ARC} distances-dir.csv TRUE"
end

file 'motifs.data' => NUMBERS_ARC do
  system "motifs.R #{NUMBERS_ARC} motifs.data 3"
end

file 'motifs4.data' => NUMBERS_ARC do
  system "motifs.R #{NUMBERS_ARC} motifs4.data 4"
end

require 'read_randesu'
file 'zscores' => 'randesu.log' do
  extract_zscores('randesu.log', 'zscores')
end

file 'randesu.log' => 'numbers.arc' do
  system "randesu numbers.arc -s 3 -r 1000 -f randesu.log"
end

if __FILE__ == $0; system "rake --trace -f #{$0} #{ARGV.join(' ')}"; end
