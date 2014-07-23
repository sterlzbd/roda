require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "session handling" do
  it "should give a warning if session variable is not available" do
    app do |r|
      r.on do
        begin
          session
        rescue Exception => e
          e.message
        end
      end
    end

    body.should =~ /use Rack::Session::Cookie/
  end

  it "should return session if available" do
    app(:bare) do
      use Rack::Session::Cookie, :secret=>'1'

      route do |r|
        r.on do
          (session[1] ||= 'a') << 'b'
          session[1]
        end
      end
    end

    _, h, b = req
    b.join.should == 'ab'
    _, h, b = req('HTTP_COOKIE'=>h['Set-Cookie'].sub("; path=/; HttpOnly", ''))
    b.join.should == 'abb'
    _, h, b = req('HTTP_COOKIE'=>h['Set-Cookie'].sub("; path=/; HttpOnly", ''))
    b.join.should == 'abbb'
  end
end
