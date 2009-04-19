#!/usr/bin/env ruby

require 'gnomecanvas2'

class Dsm < Gnome::Canvas

  def initialize(*args)
    super
  end

  def network=(net)
    @network = net
    set_scroll_region(0, 0, net.nodes.size, net.nodes.size)
    clusters = net.nodes.group_by(&:cluster).values.sort_by(&:size)
    sorted_nodes = clusters.map{ |cluster| cluster.sort_by(&:id)}.flatten
    sorted_nodes.each_with_index { |node, i| node.data.x = i }

    @network.edges.each do |e|
      x = DsmEdge.new(self.root,
        :x1 => e.from.data.x,
        :y1 => e.to.data.x,
        :x2 => e.from.data.x + 2,
        :y2 => e.to.data.x + 2,
        :fill_color => 'black',
        :outline_color => 'black')
      x.signal_connect("event") do |item, ev|
        if ev.kind_of?(Gdk::EventCrossing) && item.kind_of?(DsmEdge)
          if ev.event_type == Gdk::Event::ENTER_NOTIFY
            puts "#{e.from.id} #{e.to.id}"
          elsif ev.event_type == Gdk::Event::LEAVE_NOTIFY
            #
          end
        end
      end
    end
  end

  # zoom: set_pixels_per_unit (double n=1.0)
  # see also set_center_scroll_region   (     bool     center    ) 
end

class DsmEdge < Gnome::CanvasRect; end

if __FILE__ == $0

  require 'view_matrix'
  require 'grok'
  require 'network'
  require 'matrix_to_png'
  require 'choice'

  Choice.options do
    option :edges_file, :required => true do
      short '-e'
      long '--edges=FILE'
      desc 'File in PAIRS edges format'
      desc '(required)'
    end

    option :modules_file do
      short '-m'
      long '--modules=FILE'
      desc 'File in PAIRS modules format'
    end

    option :png_file do
      short '-o'
      long '--output=FILE.png'
      desc 'Output image file'
    end

    option :psize do
      short '-s'
      long '--size=N'
      cast Integer
      default 4
      desc 'Pixel diameter (default: 4)'
    end
  end

  c = Choice.choices

  network = Network.new
  STDERR.puts "Reading edges..."
  network.add_edges(read_pairs(c.edges_file))
  STDERR.puts "Reading modules..."
  network.set_clusters(read_pairs(c.modules_file))
  STDERR.puts "Sorting nodes according to modules..."

  Gtk.init

  window = Gtk::Window.new
  window.signal_connect("destroy") { Gtk.main_quit }

  scroll = Gtk::ScrolledWindow.new
  dsm = Dsm.new
  dsm.network = network
  scroll.add(dsm)
  window.set_default_size(640, 480)

  window.add(scroll)

  window.show_all

  Gtk.main
end
