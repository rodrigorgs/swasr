#!/usr/bin/env ruby

if __FILE__ == $0
  functions = ['clustering_coefficients', true, 'out_in_degrees', false, 'cumulative_in_degrees', true, 'cumulative_out_degrees', true]

  Dir.glob('*.rsf') do |file|
    functions.each_slice(2) do |function, log|
      outf = "#{file}-#{function}.graph"
      opt = log && '-lx -ly' || ''
      `ssrun.rb read_rsf_pairs #{file} // #{function} // puts_pairs > #{outf}`
      `ssgraph #{opt} -T png -L #{outf} < #{outf} > #{outf}.png`
    end
  end
end
