require 'gd2'

def matrix_to_png(matrix, png_file, size=1)
  height = matrix.size
  width = matrix[0].size
  h = height * size

  image = GD2::Image::TrueColor.new(width * size, height * size)
  image.draw do |canvas|
    canvas.color = GD2::Color::WHITE
    canvas.fill
    canvas.color = GD2::Color::BLACK
    matrix.each_with_index do |row, y|
      row.each_with_index do |value, x|
        canvas.rectangle(x * size, y * size, x * size + size - 1, y * size + size - 1, true) if value != 0
      end
    end
  end
  image.export(png_file)
end

if __FILE__ == $0
  x = [[0, 1, 0, 0, 1, 1, 1],
       [1, 1, 1, 0, 1, 0, 1],
       [0, 1, 1, 0, 0, 1, 0],
       [1, 0, 0, 1, 0, 0, 1]]

  matrix_to_png(x, 'teste.png', 20)
end


