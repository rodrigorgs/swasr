#def rec_map(array, &block)
#  array.map do |e|
#    if e.kind_of? Array
#      rec_map e, &block
#    else
#      block.call(e)
#    end
#  end
#end

class Dendogram
  def initialize(array)
    @array = array
  end

  def self.[](*array)
    Dendogram.new(array)
  end

  def to_a
    @array.dup
  end

  def self.equal(d1, d2)
    return false if d1.size != d2.size
    return d1[0] == d2[0] if d1.size == 1

    d2 = d2.dup
    d1.each do |x1|
      indices = (0..d2.size - 1)
      eq = indices.find { |i| Dendogram::equal(x1, d2[i]) }
      return false if eq.nil?
      d2.delete_at(eq)
    end

    return true
  end

  def ==(d2)
    return Dendogram::equal(@array, d2.to_a)
  end

  # TODO: test
  def self.createClusters(array, depth, result)
		if depth <= 0
			result << array.flatten
		else
			x0 = array[0]
			cluster0 = if x0.class == Array then x0 else [x0] end
			createClusters(cluster0, depth - 1, result)

			if array.size > 1
				x1 = array[1]
				cluster1 = if x1.class == Array then x1 else [x1] end
				createClusters(cluster1, depth - 1, result)
			end

			#if array.size > 1
      #  array = array[1..-1]
      #  array.each do |x1|
      #    cluster1 = if x1.class == Array then x1 else [x1] end
      #    createClusters(cluster1, depth - 1, result)
      #  end
			#end
		end
	end

	def self.getHeight_aux(array, base)
		if array.size == 1
			return base
		else
			return [Dendogram::getHeight_aux(array[0], base + 1), 
					Dendogram::getHeight_aux(array[1], base + 1)].max
		end
	end

	def height
		return Dendogram::getHeight_aux @array, 0
	end

  # height = 0.0 => singleton clusters
  # height = 1.0 => one big cluster
	def cut(at_height)
		result = []
		at_height = (at_height * height).to_i if at_height.class == Float
    at_height = height - at_height
		Dendogram::createClusters(@array, at_height, result)
		return result
	end
end

def fn_to_array(n, &block)
	array = Array.new(n) { Array.new(n) { 1.0 } }
	0.upto(n - 1) do |i|
		(i + 1).upto(n - 1) do |j|
			array[i][j] = array[j][i] = block.call(i, j)
		end
	end
	return array
end

# Agglomerative Hierarchical Clusterer
# 
# items is a set of items
# simfunc is 
# block should return true if the algorithm is to be interrupted
def agg_hier_cluster(items, simfunc, &block)
  block = Proc.new { nil } if block.nil?
  items = (0..items - 1).to_a if items.kind_of? Fixnum

  dendogram = []
  items.each { |e| dendogram << [e] }

  cluster1 = nil
  cluster2 = nil
  while dendogram.size > 2
    max = -1.0
    newCluster = [nil, nil]
    indices = [nil, nil]
    0.upto(dendogram.size-1) do |i|
      (i + 1).upto(dendogram.size-1) do |j|
        cluster1 = dendogram[i]
        cluster2 = dendogram[j]
        similarity = simfunc.similarity(cluster1.flatten, cluster2.flatten)
        if similarity > max
          max = similarity
          newCluster = [cluster1, cluster2]
          indices = [i, j]
        end
      end
    end
    stop = block.call(:dendogram => dendogram, :similarity => max, 
        :i => indices[0], :j => indices[1])
    break if stop

    # break if max <= 0.0000001

    newCluster.each { |e| dendogram.delete(e) }
    dendogram << newCluster
  end

  return dendogram
end

def unordered_pairs(set1, set2)
  ret = []
  size1, size2 = set1.size, set2.size
  0.upto(size1 - 1).each do |i|
    (i + 1).upto(size2 - 1).each do |j|
      ret << [set1[i], set2[j]]
    end
  end
  return ret
end

def all_pairs(set1, set2)
  ret = []
  set1.each { |e1| set2.each { |e2| ret << [e1, e2] }}
  return ret
end

class CompleteLinkage
  def initialize(item_similarity)
    @item_similarity = item_similarity
  end

  def similarity(cluster1, cluster2)
    pairs = all_pairs(cluster1, cluster2).map do |a, b| 
      @item_similarity.similarity(a, b)
    end
    return pairs.min
  end
end

class SingleLinkage
  def initialize(item_similarity)
    @item_similarity = item_similarity
  end

  def similarity(cluster1, cluster2)
    pairs = all_pairs(cluster1, cluster2).map do |a, b| 
      @item_similarity.similarity(a, b)
    end

    return pairs.max
  end
end

class TableSimilarity
  attr_accessor :table

  def initialize(table)
    @table = table
  end

  def similarity(item1, item2)
    throw "Null item!" if @table[item1][item2].nil?
    @table[item1][item2]
  end
end

def dup_table(table)
  dup = []
  table.each { |array| dup << array.dup }
  return dup
end

# TODO: test
# nearest = with greatest similarity
def knn!(table, k)
  n = table.size
  k = n if k > n

  0.upto(n - 1) do |i|
    far = (0..n-1).sort_by{ |j| table[i][j] }.reverse[k..-1]
    far.each { |j| table[i][j] = 0.0; table[j][i] = 0.0 }
  end
end

def knn(table, k)
  table_dup = dup_table(table)
  knn!(table_dup, k)
  return table_dup
end

def snn_from_knn(table)
  n = table.size
  fn_to_array(n) do |i, j|
    if table[i][j] > 0.0
      neighbors_i = (0..n-1).select {|x| table[i][x] > 0.0} 
      neighbors_j = (0..n-1).select {|x| table[j][x] > 0.0} 
      shared_neighbors = neighbors_i & neighbors_j
      shared_neighbors.size.to_f / n
    else
      0.0
    end
  end
end

require 'matrix'

def fn_to_array(n, &block)
  array = Array.new(n) { Array.new(n) { 1.0 } }
  0.upto(n - 1) do |i|
    (i + 1).upto(n - 1) do |j|
      array[i][j] = array[j][i] = block.call(i, j)
    end
  end
  return array
end

def euclidean_distance(a, b)
  x = Vector[*(a.to_a)]
  y = Vector[*(b.to_a)]
  return (x - y).r
end

def jaccard_coefficient(x, y)
  a = 0
  b_plus_c = 0
  common = x.zip(y).each do |e1, e2|
    if e1 != 0 && e2 != 0
      a += 1
    elsif e1 != 0 || e2 != 0
      b_plus_c += 1
    end
  end
  
  coef = a.to_f / (a + b_plus_c)

  return coef.nan? && 0.0 || coef
end

#def clustering_to_gxl(clustering, name="...")
##<!DOCTYPE gxl SYSTEM "http://www.gupro.de/GXL/gxl-1.0.dtd">
#  str = <<EOT
#<?xml version="1.0" encoding="UTF-8"?>
#<gxl xmlns:link="http://www.w3.org/1999/xlink" xsi:schemaLocation="http://www.gupro.de/GXL/xmlschema/gxl-1.0.xsd">
#  <graph edgemode="directed" edgeids="false" hypergraph="false" id="#{name}" >
#EOT
#
#  i = 0
#  clustering.each do |cluster|
#    cluster_name = "cluster#{i}"
#    i += 1
#    str += <<EOT
#<node id="#{cluster_name}">
#<graph edgemode="directed" edgeids="false" hypergraph="false" id="#{cluster_name}" >
#
#EOT
#    cluster.each do |item|
#      str += "<node id=\"#{item}\" />\n"
#    end
#    str += "\n</graph></node>\n"
#
#  end
#
#  str += <<EOT
#  </graph>
#</gxl>
#EOT
#
#  return str
#end

