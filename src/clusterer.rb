require 'grok'
require 'open3'
include Open3

class Clusterer
public
  def cluster(input, output, params)
    puts 'cluster()'
    ostream = new_IO(output, 'w')
    puts 'read_pairs'
    pairs = read_pairs(input).map { |a, b| [a.to_i, b.to_i] }

    puts 'arc_to_int'
    arc_to_intermediate(pairs, ostream, params)
    puts 'finish'

    ostream.close if output.kind_of?(String)
  end

  def post_process(input, output, params)
    puts 'post_process()'
    ostream = new_IO(output, 'w')
    istream = new_IO(input, 'r')

    puts 'int_to_clu'
    intermediate_to_clusters(istream, ostream, params)
    puts 'finish'

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
      File.open(param, rw)
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
    popen3 "prelude | cluster #{params}" do |stdin, stdout, stderr|
      arc_to_gdm(pairs, stdin)
      stdin.close
      ostream.write(stdout.read)
    end
  end

  # params is the height of the cut (from 0.0 to 1.0)
  def intermediate_to_clusters(istream, ostream, params)
    cmd = "prune -s#{params} | pprint"
    puts cmd
    popen3 cmd do |stdin, stdout, stderr|
      stdin.write(istream.read)
      stdin.close
      gdm_top_clusters_to_mod(stdout, ostream)
    end
  end

  # extracts the top clusters
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

if __FILE__ == $0
  clusterer = HcasClusterer.new
  clusterer.cluster("/tmp/numbers.arc", "/tmp/intermediate", "")
  clusterer.post_process("/tmp/intermediate", "/tmp/anquetil.mod", 0.90)
end

