#!/usr/bin/env ruby

def sum(list)  
  list.inject( nil ) { |sum,x| sum ? sum+x : x };  
end  

def correlation(x, y)  
  
  # Calculate the necessary values  
  n = x.size  
  
  sum_x = sum(x)  
  sum_y = sum(y)  
  
  x_squared = x.map {|item| item*item }  
  y_squared = y.map {|item| item*item }  
  
  sum_x_squared = sum(x_squared)  
  sum_y_squared = sum(y_squared)  
  
  xy = []  
  x.each_with_index do |value, key|  
    xy << value * y[key]  
  end  
  
  sum_xy = sum(xy)  
  
  # Calculate the correlation value  
  left = n * sum_xy - sum_x * sum_y  
  right = ((n * sum_x_squared - sum_x**2) * (n * sum_y_squared - sum_y**2)) ** 0.5  
  
  left / right  
end  

def readfile(name)
  return IO.readlines(name).map { |l| l.to_f }
end

x = readfile(ARGV[0])
y = readfile(ARGV[1])

puts correlation(x, y)
