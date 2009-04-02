require 'rexml/document'

include REXML

def toGXL(pairs)
  def node_id(node)
    id = node.to_s
    id = 'n' + id unless id[0..1] =~ /[A-Za-z]/
  end

  doc = REXML::Document.new <<-EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE gxl SYSTEM "http://www.gupro.de/GXL/gxl-1.0.dtd">
  EOF
  xml_root = doc.add_element 'gxl', 
      'xmlns:link' => "http://www.w3.org/1999/xlink",
      "xsi:schemaLocation" => "http://www.gupro.de/GXL/xmlschema/gxl-1.0.xsd"
  xml_graph = xml_root.add_element 'graph',
      'edgemode' => 'directed',
      'edgeids' => 'false',
      'hypergraph' => 'false',
      'id' => 'swasr'

  nodes = pairs.flatten.uniq
  nodes.each do |node|
    id = node_id(node)
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
    xml_root.add(d.root)
  end

  pairs.each do |source, target|
    source_id = node_id(source)
    target_id = node_id(target)
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
    xml_root.add(d.root)
  end
  
  return doc
end

if __FILE__ == $0
  def read_pairs(filename=nil)
    lines = filename.nil? ? STDIN.readlines : IO.readlines(filename)
    pairs = lines.map{ |line| line.strip.split(/\s+/) }
    return pairs
  end
 
  pairs = read_pairs(ARGV[0])
  doc = toGXL(pairs)

  form = Formatters::Pretty.new
  form.write(doc, $stdout)
end
