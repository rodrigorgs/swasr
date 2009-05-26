#!/usr/bin/env ruby
# Reads all the JAR files in the current directory and outputs a mapping
# between fully-qualified class/interface name and JAR file. The output can
# be used as a modules.pairs file, considering that a JAR file is a module.
#

require 'zip/zip'

def extract_modules(jar_list)
  pairs = []
  jar_list.each do |zip|
    package = File.basename(zip)
    Zip::ZipFile.foreach(zip) do |entry|
      if entry.file? && entry.to_s[-6..-1] == '.class'
        klass = entry.to_s.gsub(/\//, '.').sub(/\.class/, '')
        pairs << [klass, package]
      end
    end
  end
  return pairs
end

if __FILE__ == $0
  require 'grok'

  if ARGV.size < 2

    exit 1
  end

  pairs = extract_modules(ARGV[0..-2]) #do |zip|
  puts_pairs(pairs, ARGV[-1])
end
