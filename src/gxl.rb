#!/usr/bin/env ruby

require 'rexml/document'
require 'hpricot'
require 'grok'
require 'network'
require 'zlib'

include REXML

require 'rexml/streamlistener'

def bunch_to_mod(bunch_file, output_file)
  File.open(output_file, 'w') do |f|
    IO.readlines(bunch_file).each_with_index do |line, m|
      vertices = line[(line.index('=') + 2)..-1].strip.split(", ")
      vertices.each { |v| f.puts "#{v} #{m}" }
    end
  end
end

def pairs_to_metis(pairs, metis_file)
  pairs = read_pairs(pairs) if pairs.kind_of?(String)
  net = Network.new
  net.add_edges(pairs)
  network_to_metis!(net, metis_file)
end

def network_to_metis!(network, metis_file)
  network.nodes.each_with_index { |n, i| n.id = i + 1 }
  # TODO: transformar em nao orientado e contar arestas

  File.open(metis_file, "w") do |f|
    f.puts "#{network.nodes.size} #{network.edges.size}"
    network.nodes.sort_by{ |n| n.id }.each do |node|
      neighbors = (node.in_nodes + node.out_nodes).map{ |n| n.id}.uniq
      f.puts neighbors.join(" ")
    end
  end  
end

class DepxmlHandler2
  include StreamListener

  attr_reader :pairs

  def initialize(output)
    @output = output
    @pairs = []
  end

  def tag_start(name, attrs)
    case name
    when 'class'
      @in_class = true if attrs['confirmed'] == 'yes'
    when 'feature'
      @in_feature = true
    when 'name'
      @in_name = true
    when 'outbound'
      if attrs['confirmed'] == 'yes'
        @in_outbound = true 
        @outbound_type = attrs['type']
      end
    end
  end

  def tag_end(name)
    case name
      when 'class'; @in_class = false; @class_name = ''
      when 'feature'; @in_feature = false
      when 'name'; @in_name = false
      when 'outbound'; @in_outbound = false
      when 'dependencies'
        puts "Sorting and removing duplicates"
        puts_pairs(@pairs.sort.uniq, @output)
    end
  end

  def text(value)
    if @in_outbound
      outclass = if (@outbound_type == 'class') 
        value.gsub(/\(.*\)/, '')
      else
        class_from_feature(value)
      end
      add_edge(@class_name, outclass)
    elsif @in_class && !@in_feature && @in_name
      @class_name = value
      puts value
    end
  end

  def class_from_feature(feature)
    outclass = feature.gsub(/\(.*\)/, '')
    outclass = outclass[0..(outclass.rindex('.')-1)]
    #puts "#{feature} #{outclass}"
    return outclass
  end

  def add_edge(from, to)
    #puts "#{from} #{to}"
    @pairs << [from, to] unless (from == to || @pairs[-1] == [from, to])
  end
end

# Usa como entrada um grafo xml extraido pelo DependencyExtractor
def depxml_to_pairs2(depxml, pairsfile)
  handler = DepxmlHandler2.new(pairsfile)
  file = File.new(depxml)
  file = Zlib::GzipReader.new(file) if depxml[-3..-1] == '.gz'
  Document.parse_stream(file, handler)
  file.close
  return handler.pairs
end

# depfind.sf.net, c2c output
# Usa como entrada um grafo xml transformado pelo c2c (do depfind.sf.net)
class DepxmlHandler
  include StreamListener
  @f_from = false
  @f_to = false
  @s_from = ''
  @s_to = ''

  def initialize(output)
    @output = output
  end

  def tag_start(name, attrs)
    case name
    when 'name'; @f_from = true
    when 'outbound'; @f_to = true
    end
  end

  def text(value)
    if @f_from
      @s_from = value
      @f_from = false
    elsif @f_to
      @s_to = value.gsub(/[\[\]]/, '')
      @f_to = false
      @output.puts "#{@s_from} #{@s_to}"
    end
  end
end

def depxml_to_pairs(depxml, pairsfile)
  File.open(pairsfile, 'w') do |f|
    handler = DepxmlHandler.new(f)
    Document.parse_stream(File.new(depxml), handler)
  end
end

def gxl_to_l1(gxl, outfilename=nil)
  doc = Hpricot.XML(File.new(gxl))
  pairs = []
  doc.search("//edge") { |edge| pairs << [edge['from'], edge['to']]}
  puts_pairs(pairs, outfilename) unless outfilename.nil?
  return pairs
end

def gxl_to_l2(gxl, outfilename=nil)
  doc = Hpricot.XML(File.new(gxl))
  pairs = []
  doc.search("/gxl/graph/node/graph") do |cluster|
    cluster.search('/node') { |node| pairs << [node['id'], cluster['id']] }
  end
  puts_pairs(pairs, outfilename) unless outfilename.nil?
  return pairs
end

def create_base_gxl
  doc = REXML::Document.new <<-EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE gxl SYSTEM "http://www.gupro.de/GXL/gxl-1.0.dtd">
  EOF
  xml_root = doc.add_element 'gxl', 
      'xmlns:link' => "http://www.w3.org/1999/xlink",
      'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
      "xsi:schemaLocation" => "http://www.gupro.de/GXL/xmlschema/gxl-1.0.xsd"

  xml_graph = xml_root.add_element 'graph',
      'edgemode' => 'directed',
      'edgeids' => 'false',
      'hypergraph' => 'false',
      'id' => 'swasr'

  return doc
end

# pairs is an array of pairs, each pair containing:
#  1. node id
#  2. community id
#
# If pairs is a string, then it is treated as a filename
#
def l2_to_gxl(pairs, gxl_filename=nil?)
  pairs = read_pairs(pairs) if pairs.kind_of?(String)
  doc = create_base_gxl
  xml_graph = doc.root.elements[1]

  clusters = pairs.group_by { |node, cluster| cluster }
  clusters.each_pair do |cluster, node_list|
    node_list = node_list.map { |a, b| a }

    cluster_id = 'c' + cluster.to_s
    d = Document.new <<-EOF
      <node id="#{cluster_id}" >
        <attr name="label" >
            <string>#{cluster_id}</string>
        </attr>
        <attr name="type" >
            <string>module</string>
        </attr>
        <attr name="shortlabel" >
            <string>#{cluster_id}</string>
        </attr>
        <graph edgemode="directed" edgeids="false" hypergraph="false" id="#{cluster_id}" >
          <attr name="label" >
              <string>#{cluster_id}</string>
          </attr>
          <attr name="type" >
              <string>module</string>
          </attr>
          <attr name="shortlabel" >
              <string>#{cluster_id}</string>
          </attr>
        </graph>
      </node>
    EOF
    xml_inner_graph = d.root.elements[4]
    xml_graph.add(d.root)

    node_list.each do |node|
      id = 'n' + node.to_s
      xml_inner_graph.add_element 'node', 'id' => id
    end  
  end
  
  unless gxl_filename.nil?
    form = Formatters::Default.new
    File.open(gxl_filename, 'w') { |out| form.write(doc, out) }
  end

  return doc
end

#
# See documentation for l2_to_gxl()
#
def l1_to_gxl(pairs, gxl_filename=nil?)
  pairs = read_pairs(pairs) if pairs.kind_of?(String)
  doc = create_base_gxl
  xml_root = doc.root
  xml_graph = xml_root.elements[1]

  nodes = pairs.flatten.uniq
  nodes.each do |node|
    id = 'n' + node.to_s
    d = Document.new <<-EOF
      <node id="#{id}">
        <attr name="label">
            <string>#{id}</string>
        </attr>
        <attr name="type" >
            <string>class</string>
        </attr>
        <attr name="access" >
            <string>public</string>
        </attr>
        <attr name="shortlabel" >
            <string>#{id}</string>
        </attr>
      </node>
    EOF
    xml_graph.add(d.root)
  end

  pairs.each do |source, target|
    source_id = 'n' + source.to_s
    target_id = 'n' + target.to_s
    d = Document.new <<-EOF
      <edge from="#{source_id}" to="#{target_id}" >
        <attr name="strength" >
            <int>1</int>
        </attr>
        <attr name="type" >
            <string>depends_on</string>
        </attr>
      </edge>
    EOF
    xml_graph.add(d.root)
  end
  
  unless gxl_filename.nil?
    form = Formatters::Default.new
    File.open(gxl_filename, 'w') { |out| form.write(doc, out) }
  end
  
  return doc
end

if __FILE__ == $0
  require 'grok'

  pairs = read_pairs(ARGV[1])
  doc = (ARGV[0] == 'l1') ? l1_to_gxl(pairs) : l2_to_gxl(pairs)

  form = Formatters::Default.new
  form.write(doc, $stdout)
end

