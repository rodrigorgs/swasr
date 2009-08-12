
require 'random_graphs'
require 'fileutils'

# def gu_game(
#     size, # = 1000
#     p1,   # new node with e1 out-edges  # 0.2 steps
#     p2,   # e2 new edges
#     p3,   # rewire e3 edges
#     p4,   # delete e4 edges
#     e1,   # 1, 2, 4, 8
#     e2,   # "
#     e3,   # "
#     e4,   # "
#     alpha, # -1, 0, 1, 10, 100, 1000
#     num_modules) # ...

def pinterval(from, to)
  #return (10 * from).to_i.upto((10 * to).to_i).to_a.map { |x| x / 10.0 }
  from = 0.2 if from < 0
  return (5 * from).to_i.upto((5 * to).to_i).to_a.map { |x| x / 5.0 }
end

def e_values(p_value)
  p_value == 0.0 ? [0] : [1, 2, 4, 8]
end

def iterations(&block)
  n = 1000
  pinterval(-1, 1.0).each do |p1|
    pinterval(0.0, 1.0 - p1).each do |p2|
      pinterval(0.0, 1.0 - p1 - p2).each do |p3|
        p4 = 1.0 - p1 - p2 - p3
        e_values(p1).each do |e1|
          e_values(p2).each do |e2|
            e_values(p3).each do |e3|
              e_values(p4).each do |e4|
                [-1, 0, 1, 10, 100, 1000].each do |alpha|
                  [2, 4, 8, 16, 32].each do |m|
                    block.call([n, p1, p2, p3, p4, e1, e2, e3, e4, alpha, m])
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

# TODO: estimated time remaining
total = 0
iterations { total += 1 }
puts "total: #{total}"

pdircount = 0
count = 0
parent_dir = nil
iterations do |args| # n, p1, p2, p3, p4, e1, e2, e3, e4, alpha, m
  if (count % 100 == 0)
    parent_dir = "%05d" % pdircount
    pdircount += 1
    puts "Creating parent dir #{parent_dir}"
    FileUtils.mkdir parent_dir unless File.exist?(parent_dir)
  end
  p parent_dir
  puts "#{count} #{args.join(",")}"
  dir = "#{parent_dir}/%08d" % count
  FileUtils.mkdir dir unless File.exists?(dir)
  File.open("#{dir}/model_params", "w") { |f| f.puts(args.join("\t")) }
  count += 1
end


