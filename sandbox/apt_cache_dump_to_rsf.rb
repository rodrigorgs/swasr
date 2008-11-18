#!/usr/bin/env ruby

# run 
#   apt-cache dump
# and redirect the output to this script

if __FILE__ == $0
  package = ''
  STDIN.each_line do |line|
    if line =~ /^Package: (.+)$/
      package = $1
      puts "$INSTANCE #{package} package"
    end
    
    if line =~ /^\s*Depends: ([^\s]+)/
      puts "depends #{package} #{$1}"
    end
  end
end
