require 'png'

def matrix_to_png(matrix, png_file, size=1)
  height = matrix.size
  width = matrix[0].size
  h = height * size

  canvas = PNG::Canvas.new width * size, height * size, PNG::Color::White
  matrix.each_with_index do |row, y|
    row.each_with_index do |value, x|
      if value != 0
        (x * size).upto(x * size + size - 1) do |i|
          (y * size).upto(y * size + size - 1) do |j|
            canvas[i, h - j - 1] = PNG::Color::Black
          end
        end
      end
    end
  end
  png = PNG.new(canvas)
  png.save(png_file)
end

if __FILE__ == $0
  x = [[0, 1, 0, 0, 1, 1, 1],
       [1, 1, 1, 0, 1, 0, 1],
       [0, 1, 1, 0, 0, 1, 0],
       [1, 0, 0, 1, 0, 0, 1]]

  matrix_to_png(x, 'teste.png', 20)
end


