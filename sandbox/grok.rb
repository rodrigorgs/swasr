#!/usr/bin/env ruby

def read_rsf_pairs(filename=nil, relations=[])
	relations = [relations] if !relations.kind_of?(Array)

	pairs = []
  if filename.nil?
    lines = STDIN.readlines
  else
  	lines = IO.readlines(filename)
  end
	lines.map{ |line| line.strip.split(/\s+/) }.each do |rel, e1, e2|
		pairs << [e1, e2] if relations.empty? || relations.include?(rel)
	end

	return pairs
end

def entities(pairs)
  pairs.flatten.uniq
end

# returns a hash relation_name => pair
def getdb(filename=nil)
  file = filename.nil? && STDIN || File.open(filename, 'r')

  ret = {}
  file.each_line do |line|
    line = line.strip
    next if line.size == 0 || line[0] == '#'
    triple = line.split(/\s+/)
    relation, pair = triple[0], triple[1..2]
    hash[pair] ||= []
    hash[pair] << pair
  end

  file.close unless file == STDIN
  return ret
end

def puts_pairs(pairs)
  pairs.each { |x, y| puts "#{x} #{y}" }
end

def grep(pairs, regex1, regex2=/.*/)
  pairs.select { |x, y| x =~ regex1 && y =~ regex2 }
end
