if __FILE__ == $0
  require 'rgl/adjacency'
  require 'rgl/topsort'

  g = RGL::DirectedAdjacencyGraph[7,11, 7,8, 5,11, 3,8, 3,10, 11,2, 11,9, 11,10,
      8,9,]

  #sort = Array.new
  sort = [7,5,3,11,8,2,10,9]
  #sort << [7,5,11,2,3,10,8,9]
  #sort << [3,7,8,5,11,10,9,2]
  #sort << [3,5,7,11,10,2,8,9]

  (1..sort.size-1).each do |i|
    c1, c2 = sort[0..i-1], sort[i..sort.size]
    File.open("graph#{i}.dot", 'w') do |file|
    file.puts <<EOT
      digraph XYZ {
        subgraph cluster_1 {
          #{c1.join('; ') + ';' }
        }
        subgraph cluster_2 {
          #{c2.join('; ') + ';' }
        }

        #{g.edges.map{ |e| "#{e.source}->#{e.target}; " }.join("")}
        
      }
EOT
    end
  end
end
