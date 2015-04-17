require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "heartbeat plugin" do 
  it "should return heartbeat response for heartbeat paths only" do
    app(:bare) do
      plugin :heartbeat
      route do |r|
        r.on 'a' do
          "a"
        end
      end
    end

    body('/a').should == 'a'
    status.should == 404
    status('/heartbeat').should == 200
    body('/heartbeat').should == 'OK'
  end

  it "should support custom heartbeat paths" do
    app(:bare) do
      plugin :heartbeat, :path=>'/heartbeat2'
      route do |r|
        r.on 'a' do
          "a"
        end
      end
    end

    body('/a').should == 'a'
    status.should == 404
    status('/heartbeat').should == 404
    status('/heartbeat2').should == 200
    body('/heartbeat2').should == 'OK'
  end

  it "should work when using sessions" do
    app(:bare) do
      use Rack::Session::Cookie, :secret=>'foo'
      plugin :heartbeat

      route do |r|
        session.clear
        r.on "a" do
          "a"
        end
      end
    end

    body('/a').should == 'a'
    status.should == 404
    status('/heartbeat').should == 200
    body('/heartbeat').should == 'OK'
  end

  it "should work when redirecting" do
    app(:bare) do
      plugin :heartbeat

      route do |r|
        r.on "a" do
          "a"
        end
        r.redirect '/a'
      end
    end

    body('/a').should == 'a'
    status.should == 302
    status('/heartbeat').should == 200
    body('/heartbeat').should == 'OK'
  end
end

