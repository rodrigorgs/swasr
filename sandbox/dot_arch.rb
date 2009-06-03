require 'network'

net = Network.new
net.load2('arch')

File.open("arch.dot", "w") { |f| f.write(net.to_dot) }
system "dot -Tpng arch.dot > arch.png"
system "eog arch.png"
