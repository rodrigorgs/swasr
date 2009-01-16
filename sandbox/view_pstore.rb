require 'pstore'

class Navigator < Shoes
  url "/", :index
  url "/systems/(.+)", :view_system

  def index
    view_system(nil)
  end

  def view_system(name)
    store = PStore.new('metrics.pstore')
    flow do

      stack :width => '33%' do
        store.transaction(true) do |s|
          s.roots.each do |system|
            link1 = link(system, :click => "/systems/#{system}")
            link2 = link('[del]') do
              puts 1
              link1.hide
              link1.remove
              store.transaction do
                store.delete system
                store.commit
              end
            end
            para link1, " ", link2
                
          end
        end
      end

      stack :width => '67%' do
        if name.nil?
          break
        end

        store.transaction(true) do |s|
          s[name].each_pair do |key, value|
            para strong(key), " -- #{value}", link("del") { puts 1 }
          end
        end
      end

    end
  end
end

Shoes.app(:width => 640, :height => 480, :title => "Navigator")
