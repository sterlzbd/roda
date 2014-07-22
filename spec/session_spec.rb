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

    body.should =~ /Sinuba.use Rack::Session::Cookie/
  end

  it "should return session if available" do
    app(:bare) do
      use Rack::Session::Cookie, :secret=>'1'

      route do |r|
        r.on do
          session[1] = 'a'
          session[1]
        end
      end
    end

    body.should == 'a'
  end
end
