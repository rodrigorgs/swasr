#!/usr/bin/env ruby

require 'matrix'

# distance between complex networks

# m1 and m2 are the distance matrices for the two networks
def distance(m1, m2)
  n = m1.size
  sum = 0.0
  n.times do |i|
    n.times do |j|
      dif = m2[i][j] - m1[i][j]
      sum += dif * dif
    end
  end
  sum
end

# matrix is an array of arrays
# swaps two lines in a matrix. the corresponding cells are swapped.
def swap_line!(matrix, i, j)
  matrix[i], matrix[j] = matrix[j], matrix[i]
  matrix.each { |array| array[i], array[j] = array[j], array[i] }
end


# monte carlo distance
def mcdistance(m1, m2, t=1)
  n = m1.size
  stable_iterations = 0
  iterations = 0

  puts "======= #{n} ========="

  mindist = distance(m1, m2)
  newdist = mindist
  fastdist = mindist
  while iterations < n
    iterations += 1
    puts "#{iterations} #{mindist} #{mindist / (n * (n - 1))}"

    i = rand(n)
    begin j = rand(n) end until j != i

    n.times { |x| d = (m2[i][x] - m1[i][x]); fastdist -= d*d }
    n.times { |x| d = (m2[j][x] - m1[j][x]); fastdist -= d*d }
    n.times { |x| d = (m2[x][i] - m1[x][i]); fastdist -= d*d }
    n.times { |x| d = (m2[x][j] - m1[x][j]); fastdist -= d*d }
    d = m2[i][i] - m1[i][i]; fastdist += d * d
    d = m2[i][j] - m1[i][j]; fastdist += d * d
    d = m2[j][i] - m1[j][i]; fastdist += d * d
    d = m2[j][j] - m1[j][j]; fastdist += d * d

    swap_line!(m2, i, j)

    n.times { |x| d = (m2[i][x] - m1[i][x]); fastdist += d*d }
    n.times { |x| d = (m2[j][x] - m1[j][x]); fastdist += d*d }
    n.times { |x| d = (m2[x][i] - m1[x][i]); fastdist += d*d }
    n.times { |x| d = (m2[x][j] - m1[x][j]); fastdist += d*d }
    d = m2[i][i] - m1[i][i]; fastdist -= d * d
    d = m2[i][j] - m1[i][j]; fastdist -= d * d
    d = m2[j][i] - m1[j][i]; fastdist -= d * d
    d = m2[j][j] - m1[j][j]; fastdist -= d * d

    olddist = newdist
    newdist = fastdist #distance(m1, m2)

    #newdist = distance(m1, m2)
    #raise "Erro" if fastdist != newdist

    if (newdist < mindist)
      mindist = newdist
    end
    #if rand > iterations / n.to_f
    #  newdist = olddist
    #  swap_line!(m2, i, j)
    #end
    
  end

  return mindist
end

#n = 1658

def file_to_matrix(file)
  return IO.readlines(file).map { |line| line.split(" ").map { |s| s.to_i } }
end

puts 'loading a'
a = file_to_matrix(ARGV[0])
puts 'loading b'
b = file_to_matrix(ARGV[1])

#a = NMatrix.int(n, n)
#a.random!(n)
#a.diagonal!(0)
#b = NMatrix.int(n, n)
#b.random!(n)
#b.diagonal!(0)


#a = [[0, 1, 2, 3],
#     [1, 0, 2, 3],
#     [1, 2, 0, 3],
#     [1, 2, 3, 0]]
#
#b = [[0, 2, 5, 3],
#     [1, 0, 2, 3],
#     [5, 2, 0, 4],
#     [4, 2, 3, 0]]

#b = a.dup
#swap_line!(b, 0, 1)

puts mcdistance(a, b)
