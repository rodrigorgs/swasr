if __FILE__ == $0

require 'pstore'

$STORE = PStore.new('metrics.pstore')

class Navigator < Shoes
  url "/", :index
  url "/systems/(.+)", :view_system
  url "/params/(.+)", :view_param

  def index
    view_system(nil)
  end

  def view_system(name)
    flow do

      stack :width => '33%' do
        background yellow

        systems = nil
        $STORE.transaction(true) { |s| systems = s.roots.dup }
        systems.each do |system|
          fl = flow do
            para link(system, :click => "/systems/#{system}")
            image('/tmp/trash.gif', :click => Proc.new {
              $STORE.transaction { |s| s.delete system }
              fl.hide
            })
          end  
        end
      end

      stack :width => '67%' do
        if name.nil?
          break
        end

        $STORE.transaction(true) do |s|
          s[name].each_pair do |key, value|
            para strong(key), " -- #{value}"#, link("del") { puts 1 }
          end
        end
      end

    end
  end
end

Shoes.app(:width => 640, :height => 480, :title => "Navigator")

end
