require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "flash plugin" do 
  it "flash.now[] sets flash for current page" do
    app(:bare) do
      use Rack::Session::Cookie, :secret => "1"
      plugin :flash

      route do |r|
        r.on do
          flash.now['a'] = 'b'
          flash['a']
        end
      end
    end

    body.should == 'b'
  end

  it "flash[] sets flash for next page" do
    app(:bare) do
      use Rack::Session::Cookie, :secret => "1"
      plugin :flash

      route do |r|
        r.on 'a' do
          "c#{flash['a']}"
        end

        r.on do
          flash['a'] = "b#{flash['a']}"
          flash['a'] || ''
        end
      end
    end

    env = proc{|h| h['Set-Cookie'] ? {'HTTP_COOKIE'=>h['Set-Cookie'].sub("; path=/; HttpOnly", '')} : {}}
    _, h, b = req
    b.join.should == ''
    _, h, b = req(env[h])
    b.join.should == 'b'
    _, h, b = req(env[h])
    b.join.should == 'bb'
    _, h, b = req('/a', env[h])
    b.join.should == 'cbbb'
    _, h, b = req(env[h])
    b.join.should == ''
    _, h, b = req(env[h])
    b.join.should == 'b'
    _, h, b = req(env[h])
    b.join.should == 'bb'
  end
end

describe "FlashHash" do 
  before do
    @h = Roda::RodaPlugins::Flash::FlashHash.new
  end

  it ".new should accept nil for empty hash" do
    @h = Roda::RodaPlugins::Flash::FlashHash.new(nil)
    @h.now.should == {}
    @h.next.should == {}
  end

  it ".new should accept a hash" do
    @h = Roda::RodaPlugins::Flash::FlashHash.new(1=>2)
    @h.now.should == {1=>2}
    @h.next.should == {}
  end

  it "#[]= assigns to next flash" do
    @h[1] = 2
    @h.now.should == {}
    @h.next.should == {1=>2}
  end

  it "#discard removes given key from next hash" do
    @h[1] = 2
    @h[nil] = 3
    @h.next.should == {1=>2, nil=>3}
    @h.discard(nil)
    @h.next.should == {1=>2}
    @h.discard(1)
    @h.next.should == {}
  end

  it "#discard removes all entries from next hash with no arguments" do
    @h[1] = 2
    @h[nil] = 3
    @h.next.should == {1=>2, nil=>3}
    @h.discard
    @h.next.should == {}
  end

  it "#keep copies entry for key from current hash to next hash" do
    @h.now[1] = 2
    @h.now[nil] = 3
    @h.next.should == {}
    @h.keep(nil)
    @h.next.should == {nil=>3}
    @h.keep(1)
    @h.next.should == {1=>2, nil=>3}
  end

  it "#keep copies all entries from current hash to next hash" do
    @h.now[1] = 2
    @h.now[nil] = 3
    @h.next.should == {}
    @h.keep
    @h.next.should == {1=>2, nil=>3}
  end

  it "#sweep replaces current hash with next hash" do
    @h[1] = 2
    @h[nil] = 3
    @h.next.should == {1=>2, nil=>3}
    @h.now.should == {}
    @h.sweep.should == {1=>2, nil=>3}
    @h.next.should == {}
    @h.now.should == {1=>2, nil=>3}
  end
end
