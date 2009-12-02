#!/usr/bin/env ruby
require 'network_base'
require 'open3'
require 'tempfile'
require 'tmpdir'
require 'stringio'
require 'fileutils'
include Open3

class Clusterer

public
  def self.acdc(arcs_string, params)
    out = StringIO.new
    clusterer = AcdcClusterer.new
    clusterer.cluster(arcs_string, out, params)
    raise 'Empty decomposition' if out.string.strip.empty?
    return out.string
  end
  
  def self.hcas(arcs_string, params)
    inter = StringIO.new
    out = StringIO.new
    clusterer = HcasClusterer.new
    clusterer.cluster(arcs_string, inter, params)
    inter.rewind
    clusterer.post_process(inter, out, params)
    raise 'Empty decomposition' if out.string.strip.empty?
    return out.string
  end
  
  def self.infomap(arcs_string, params)
    out = StringIO.new
    clusterer = InfomapClusterer.new
    clusterer.cluster(arcs_string, out, params)
    raise 'Empty decomposition' if out.string.strip.empty?
    return out.string
  end
  
  def self.bunch(arcs_string, params)
    out = StringIO.new
    clusterer = BunchClusterer.new
    clusterer.cluster(arcs_string, out, params)
    raise 'Empty decomposition' if out.string.strip.empty?
    return out.string
  end

  ###################################################################### 

  def cluster(input, output, params)
    ostream = new_IO(output, 'w')
    #pairs = read_pairs(input).map { |a, b| [a.to_i, b.to_i] }
    pairs = pairs_from_string(input).map { |a, b| [a.to_i, b.to_i] }

    arc_to_intermediate(pairs, ostream, params)

    ostream.close if output.kind_of?(String)
  end

  def post_process(input, output, params)
    ostream = new_IO(output, 'w')
    istream = new_IO(input, 'r')

    intermediate_to_clusters(istream, ostream, params)

    ostream.close if output.kind_of?(String)
    istream.close if input.kind_of?(String)
  end

protected
  def arc_to_intermediate(pairs, ostream, params)
  end

  def intermediate_to_clusters(istream, ostream, params)
  end
  
  def new_IO(param, rw)
    return (if param.nil? then
      STDOUT
    elsif param.kind_of?(String)
      #File.open(param, rw)
      StringIO.new(param)
    else
      param
    end)
  end

end

# Pre-requisites:
# Command line utilities prelude, cluster, prune, and pprint must be in PATH
#
class HcasClusterer < Clusterer # by Nicolas Anquetil
protected

  def arc_to_gdm(pairs, ostream)
    array = numbered_pairs_to_adjacency_list(pairs)
    array.each_with_index { |neighbors, node| ostream.puts "#{node} #{neighbors.join(' ')}" }
  end

  # params is a string that is given to the command ``cluster''.
  def arc_to_intermediate(pairs, ostream, params)
    cmd_params = " -#{params[:coefficient]} -l#{params[:linkage]}"
    cmd = "prelude | cluster #{cmd_params}"
    LOG.info(cmd)
    popen3 cmd do |stdin, stdout, stderr|
      arc_to_gdm(pairs, stdin)
      stdin.close
      ostream.write(stdout.read)
    end
  end

  # params is the height of the cut (from 0.0 to 1.0)
  def intermediate_to_clusters(istream, ostream, params)
    cmd = "prune -s#{params[:cut_height]} | pprint"
    LOG.info(cmd)
    popen3 cmd do |stdin, stdout, stderr|
      stdin.write(istream.read)
      stdin.close
      gdm_top_clusters_to_mod(stdout, ostream)
    end
  end

  # extracts the topmost clusters
  #
  # From http://web.archive.org/web/20050427174815/http://www.csi.uottawa.ca/~anquetil/Clusters/index.html :
  # Usually, what you want is the top most clusters. 
  # These can be optained in prolog (after a subsequent `pprint') with: 
  # couple(ID,Entities,_),not arc(_,ID). 
  # That is to say all clusters which do not have parent in the hierarchy.
  def gdm_top_clusters_to_mod(istream, ostream)
    hash = Hash.new
    istream.each_line do |line|
      if line =~ /^couple\((\d+),\[(.+?)\]/
        hash[$1.to_i] = $2
      elsif line =~ /^arc\(.*,(\d+)/
        hash.delete($1.to_i)
      end
    end

    i = 0
    hash.each_value do |v|
      v.split(",").each { |node| ostream.puts "#{node} #{i}" }
      i += 1
    end
  end
end

# Pre-requisite: acdc must be in CLASSPATH
class AcdcClusterer < Clusterer

  def arc_to_intermediate(pairs, ostream, params)
    cmd_params = params[:patterns] || '+bso'
    cmd_params.downcase!
    cmd_params += " -u" if params[:top_level_clusters]
    cmd_params += " -l#{params[:max_cluster_size]}" if params[:max_cluster_size]

    ifile = "#{Dir.tmpdir}/input.rsf"
    File.open(ifile, "w") do |f|
      pairs.each { |a, b| f.puts "depend #{a} #{b}" }
    end

    ofile = "#{Dir.tmpdir}/output.rsf"
    cmd = "java -server acdc.ACDC #{ifile} #{ofile} #{cmd_params}"
    LOG.info(cmd)
    #cmd = "acdc.exe #{ifile} #{ofile} #{cmd_params}"
    system cmd
    lastmod = nil
    mod = -1
    IO.foreach(ofile) do |line|
      pair = line.split(" ")[1..2]
      if pair[0] != lastmod
        lastmod = pair[0]
        mod += 1
      end
      ostream.puts "#{pair[1]} #{mod}"
    end
  end
end

class InfomapClusterer < Clusterer
  def arc_to_intermediate(pairs, ostream, params={})
    seed = params[:seed] || 0
    attempts = params[:attempts] || 10

    t = Tempfile.new('infomap')
    path = t.path
    t.delete

    pairs.map! { |a, b| [a+1, b+1] }

    File.open(path + '.net', 'w') do |f|
      vertices = entities(pairs)
      n = vertices.max
      f.puts("*Vertices #{n}")
      1.upto(n) { |x| f.puts "#{x} \"#{x}\"" }
      f.puts("*Arcs #{pairs.size}")
      pairs.each { |a, b| f.puts "#{a} #{b} 1" }
    end
    
    cmd = "infomap #{seed} #{path}.net #{attempts}"
    puts cmd
    system cmd#("infomap #{seed} #{path}.net #{attempts}")
    raise RuntimeError, "Error running infomap." if ($? != 0)

    IO.foreach(path + '.tree') do |line|
      if line =~ /^(\d+):.*?"(\d+?)"/
        ostream.puts "#{$2.to_i - 1} #{$1.to_i - 1}"
      end
    end

    FileUtils.rm_f(Dir.glob(path + '*').to_a)

  end
end

class BunchClusterer < Clusterer
  def arc_to_intermediate(pairs, ostream, params={})
    t = Tempfile.new('bunch')
    path = t.path
    t.delete
    put_pairs(pairs, path)

    cmd = "java BunchCmd #{path}"
    puts cmd
    popen3 cmd do |stdin, stdout, stderr|
      ostream.write(stdout.read)
    end

    FileUtils.rm_f(path)
  end  
end

if __FILE__ == $0
  #puts Clusterer::infomap(IO.read('/tmp/numbers.arc'), {})
  puts Clusterer::bunch(IO.read('/tmp/numbers.arc'), {})
  #clusterer = AcdcClusterer.new
  #clusterer.cluster("/tmp/numbers.arc", "/tmp/acdc.mod", "-l9999 -u")
  #
  #exit 0

  #clusterer = HcasClusterer.new
  #clusterer.cluster("/tmp/numbers.arc", "/tmp/intermediate", "")
  #clusterer.post_process("/tmp/intermediate", "/tmp/anquetil.mod", 0.90)
end


