require 'matrix'

# In all cases, a and b are vectors with the same size, and the values
# of each vector sum to 1.

# the less, the better
def euclidean_distance(a, b)
  x = Vector[*(a.to_a)]
  y = Vector[*(b.to_a)]
  return (x - y).r
end

# the less, the better
def histogram_intersection_distance(a, b)
  sum = 0.0
  a.size.times do |i|
    sum += [a[i], b[i]].min
  end
  return 1 - sum
end

# the less, the better
def minkowski_distance(a, b, p)
  sum = 0.0
  a.size.times do |i|
    sum += Math.abs(a[i] - b[i]) ** p
  end
  return sum ** (1.0/p)
end

# the less, the better
# Sarabandi, p. 100
def modified_chi_squared(a, b)
  sum = 0.0
  a.size.times do |i|
    sum += ((a[i] - b[i]) ** 2) / (a[i] + b[i])
  end
  return sum
end

# the less, the better
# symmetric
def kl_divergence(a, b)
  sum = 0.0
  a.size.times do |i|
    sum += (a[i] - b[i]) * Math.log(a[i] / b[i]) if a[i] > 0.00000001
  end
  return sum
end

def log_or_zero(x)
  x == 0 ? 0 : Math.log(x)
end

def entropy(a)
  log2 = Math.log(2)
  return -a.inject(0.0) { |sum, x| sum + (x * (log_or_zero(x) / log2)) }
end

# the less, the better
def entropy_distance(a, b)
  return (entropy(a) - entropy(b)).abs
end

def sum(list)  
  list.inject( nil ) { |sum,x| sum ? sum+x : x };  
end  

# http://blog.trevorberg.com/2008/08/13/standard-deviation-and-correlation-coefficient-in-ruby/
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

