require File.expand_path("spec_helper", File.dirname(__FILE__))

begin
  require 'sinatra/flash/hash'
rescue LoadError
  warn "sinatra-flash not installed, skipping flash plugin test"  
else
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
end
