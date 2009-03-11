require 'graph_metrics'
require 'grok'

def border(pairs, set1, set2)
  #border_pairs = grep(pairs, regex1, regex2)
  border_pairs = pairs.select { |x, y| set1.include?(x) && set2.include?(y) }

  origin = border_pairs.map{ |x, y| x }.uniq
  target = border_pairs.map{ |x, y| y }.uniq
  origin_pairs = pairs.select{ |x,y| origin.include?(x) && origin.include?(y) }
  target_pairs = pairs.select{ |x,y| target.include?(x) && target.include?(y) }
  return {:border_pairs => border_pairs, :origin => origin, :target => target,
      :origin_pairs => origin_pairs, :target_pairs => target_pairs,
      :pairs => border_pairs + origin_pairs + target_pairs}
end

def border_regex(pairs, regex1, regex2)
  regex1 = Regexp.new(regex1) if regex1.kind_of? String
  regex2 = Regexp.new(regex2) if regex2.kind_of? String

  ent = entities(pairs)
  set1 = ent.select{ |x| x =~ regex1 }.uniq
  set2 = ent.select{ |x| x =~ regex2 }.uniq
  return border(pairs, set1, set2)
end

def border_clustering_coefficient(pairs, regex1, regex2)
  b = border_regex(pairs, regex1, regex2)
  origin = b[:origin]
  cc = node_clustering_coefficients(b[:pairs])
  cc.delete_if { |key, value| !origin.include?(key) }
  return cc.values.sort_by { |k, c_k| k }
end

def border_out_in_degrees(pairs, regex1, regex2)
  b = border_regex(pairs, regex1, regex2)
  out_in_degrees(b[:pairs])
end

if __FILE__ == $0
  pairs = [
    %w[a1 b1],
    %w[a1 b2],
    %w[a1 a2],
    %w[a2 b1],
    %w[a2 b3],
    %w[b1 b3],
  ]

  p border(pairs, /a/, /b/)
end
