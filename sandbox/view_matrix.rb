require 'tempfile'
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

def fn_to_matrix(n, &block)
	array = fn_to_array(n, &block)
	return Matrix[*array]
end

# matrix instanceof Matrix
def view_matrix(matrix, labels)
  matrix = Matrix[*matrix] if matrix.kind_of? Array

	tmp = Tempfile.new('mview')
	path = tmp.path
	tmp.close!

	File.open(path, 'w') do |file|
		file.puts '<table border="0" cellpadding="0" cellspacing="0">'
		file.puts "<tr><td></td>"
		0.upto(matrix.row_size-1) { |i| file.puts "<td align=\"center\">#{i}</td>" }
		file.puts "</tr>"
		0.upto(matrix.row_size-1) do |i|
			file.puts "<tr><td><tt><b>#{'%3i' % i}</b></tt>&nbsp;#{labels[i]}</td>"
			matrix.row(i) do |n|
				color = "#00#{"%02X" % (255*n).to_i}00"
				file.puts "<td bgcolor=\"#{color}\">#{'%.2f' % n}</td>" 
			end
			file.puts '</tr>'
		end
	end

	`firefox #{path}`
	#file.close
end

# matrix instanceof Matrix
def view_matrix2(matrix)
  matrix = Matrix[*matrix] if matrix.kind_of? Array

	tmp = Tempfile.new('mview')
	path = tmp.path
	tmp.close!

	File.open(path, 'w') do |file|
		file.puts '<table border="0" cellpadding="0" cellspacing="0">'
		0.upto(matrix.row_size-1) do |i|
			file.puts "<tr>"
			matrix.row(i) do |n|
        value = "%02X" % (255*(1.0 - n)).to_i
				color = "#" + (value * 3)
				file.puts "<td width=\"1\" height=\"1\" bgcolor=\"#{color}\"></td>" 
			end
			file.puts '</tr>'
		end
    file.puts "</table>"
	end

	`firefox #{path}`
	#file.close
end

# matrix instanceof array of arrays of float(0,1)
def view_matrix_dots(matrix, cellsize=3)
	tmp = Tempfile.new('mview')
	path = tmp.path
	tmp.close!

	File.open(path, 'w') do |file|
		file.puts '<table border="0" cellpadding="0" cellspacing="0">'
		matrix.each do |row|
			file.puts "<tr>"
			row.each do |n|
				color = "#00#{"%02X" % (255*n).to_i}00"
				file.puts "<td bgcolor=\"#{color}\" width=\"#{cellsize}\" height=\"#{cellsize}\"></td>" 
			end
			file.puts '</tr>'
		end
	end

	`firefox #{path}`
end

def view_matrix_as_list(matrix, labels)
	tmp = Tempfile.new('mlist')
	path = tmp.path
	tmp.close!
	

	File.open(path, 'w') do |file|
		file.puts "<html><body><ul>"
		0.upto(labels.size-1) do |i|
			file.puts "<li>#{labels[i]}</li>"
			file.puts "<ul>"
			indices = (0..labels.size - 1).sort_by{ |x| matrix[i, x] }.reverse
			indices.delete i
			indices.each do |j|
				sim = "#{'%.2f' % matrix[i, j]}"
				value = "%02X" % (255 * (1.0 - matrix[i, j]))
				sim = "<font color=\"\##{value}#{value}C0\">#{sim}</font>"
				file.puts "<li><tt>#{sim}</tt>&nbsp;#{labels[j]}</li>"
			end
			file.puts "</ul>"
		end
		file.puts "</ul></body></html>"
	end

	`firefox #{path}`
end

def view_matrix_pairs(matrix, labels)
	tmp = Tempfile.new('mpairs')
	path = tmp.path
	tmp.close!
	
	File.open(path, 'w') do |file|
		array = []
		n = labels.size
		0.upto(n-1) do |i|
			(i+1).upto(n-1) { |j| array << [matrix[i, j], i, j] }
		end
		array = array.sort_by{ |a| a[0] }.reverse

		file.puts '<table border="1">'
		array.each do |x|
			file.puts "<tr><td>#{'%.2f' % x[0]}</td>"
			file.puts "<td>#{labels[x[1]]}</td><td>#{labels[x[2]]}</td></tr>"
		end
		file.puts '</table>'
	end

	`firefox #{path}`
end

# matrix is an array of arrays
# swaps two lines in a matrix. the corresponding cells are swapped.
def swap_line!(matrix, i, j)
	matrix[i], matrix[j] = matrix[j], matrix[i]
	matrix.each { |array| array[i], array[j] = array[j], array[i] }
end


# clusters is an array of arrays of ints (or, optionally, an array of ints)
def sort_matrix!(matrix, clusters)
	i = 0
	clusters.flatten.each do |j|
		swap_line! matrix, i, j unless i <= j
    puts "swap #{i}, #{j}"
		i += 1
	end
end

####################################

if __FILE__ == $0
	require 'test/unit'
	include Test::Unit::Assertions

	x = [[1,2,3],[4,5,6],[7,8,9]]

	y = x.dup
	swap_line! y, 0, 1
	assert_equal y, [[5,4,6],[2,1,3],[8,7,9]]

	z = x.dup
	sort_matrix! z, [1, 0, 2]
	assert_equal y, z
end

