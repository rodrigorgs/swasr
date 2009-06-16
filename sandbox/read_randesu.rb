#!/usr/bin/env ruby

# filename is a file the output of the RAND-ESU tool
# http://theinf1.informatik.uni-jena.de/~wernicke/motifs/index.html
def zscores(filename)
  start = false
  scores = {36 => 0, 6 => 0, 12 => 0, 38 => 0, 14 => 0, 164 => 0, 78 => 0,
  46 => 0, 166 => 0, 102 => 0, 174 => 0, 140 => 0, 238 => 0}
  IO.readlines(filename).each do |line|
    if !start 
      start = true if line =~ /ID .*Adj .* Z-Score/
    else
      fields = line.strip.split(/\s+/)
      if fields.size > 5
        scores[fields[0].to_i] = fields[5].to_f
      end
    end
  end
  return scores
end

def extract_zscores(input, output)
  z = zscores(input).sort_by { |id,_| id}

  File.open(output, "w") do |f|
    z.each { |id, score| f.puts score }
  end
end

if __FILE__ == $0
  if ARGV.size != 2
    puts "
    Extract z-scores from the output file of RAND-ESU (from FANMOD's website).

    Parameters: input output
    "
  end

  input, output = ARGV
  extract_zscores(input, output)
end
