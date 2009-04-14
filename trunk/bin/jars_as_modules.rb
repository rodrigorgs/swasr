#!/usr/bin/env ruby
# Reads all the JAR files in the current directory and outputs a mapping
# between fully-qualified class/interface name and JAR file. The output can
# be used as a modules.pairs file, considering that a JAR file is a module.
#

require 'zip/zip'

Dir.glob("*.jar") do |zip|
  package = File.basename(zip)
  Zip::ZipFile.foreach(zip) do |entry|
    if entry.file? && entry.to_s[-6..-1] == '.class'
      klass = entry.to_s.gsub(/\//, '.').sub(/\.class/, '')
      puts "#{klass} #{package}"
    end
  end
end
