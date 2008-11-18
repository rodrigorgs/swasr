# cd `dirname $0`
# require todos os arquivos plot/*

module Plot
# plot to plotutils graph ascii dataset format
def plot_pairs(data)
  if data.kind_of?(Hash)
    data.keys.sort.each do |key|
      array = data[key]
      plot_pairs(data)
      puts
    end
  end
  
  data.each { |x, y| puts "#{x} #{y}" }
end

end