#!/usr/bin/env ruby

require 'rexml/document'
require 'hpricot'

include REXML

def gxl_to_l1(filename)
  doc = Hpricot.XML(File.new(filename))
  pairs = []
  doc.search("//edge") { |edge| pairs << [edge['from'], edge['to']]}
  return pairs
end

def gxl_to_l2(filename)
  doc = Hpricot.XML(File.new(filename))
  pairs = []
  doc.search("/gxl/graph/node/graph") do |cluster|
    cluster.search('/node') { |node| pairs << [node['id'], cluster['id']] }
  end
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
def l2_to_gxl(pairs)
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
  return doc
end

def l1_to_gxl(pairs)
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
  
  return doc
end

if __FILE__ == $0
  def read_pairs(filename=nil)
    lines = filename.nil? ? STDIN.readlines : IO.readlines(filename)
    pairs = lines.map{ |line| line.strip.split(/\s+/) }
    return pairs
  end
 
  pairs = read_pairs(ARGV[1])
  doc = (ARGV[0] == 'l1') ? l1_to_gxl(pairs) : l2_to_gxl(pairs)

  form = Formatters::Default.new
  form.write(doc, $stdout)
end

