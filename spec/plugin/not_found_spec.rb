require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "not_found plugin" do 
  it "executes on no arguments" do
    app(:bare) do
      plugin :not_found

      not_found do
        "not found"
      end

      route do |r|
        r.on "a" do
          "found"
        end
      end
    end

    body.should == 'not found'
    status.should == 404
    body("/a").should == 'found'
    status("/a").should == 200
  end

  it "allows overriding status inside not_found" do
    app(:bare) do
      plugin :not_found

      not_found do
        response.status = 403
        "not found"
      end

      route do |r|
      end
    end

    status.should == 403
  end

  it "calculates correct Content-Length" do
    app(:bare) do
      plugin :not_found do
        "a"
      end

      route{}
    end

    header('Content-Length').should == "1"
  end

  it "clears existing headers" do
    app(:bare) do
      plugin :not_found do ||
        "a"
      end

      route do |r|
        response['Content-Type'] = 'text/pdf'
        response['Foo'] = 'bar'
        nil
      end
    end

    header('Content-Type').should == 'text/html'
    header('Foo').should == nil
  end

  it "does not modify behavior if not_found is not called" do
    app(:not_found) do |r|
      r.on "a" do
        "found"
      end
    end

    body.should == ''
    body("/a").should == 'found'
  end

  it "can set not_found via the plugin block" do
    app(:bare) do
      plugin :not_found do
        "not found"
      end

      route do |r|
        r.on "a" do
          "found"
        end
      end
    end

    body.should == 'not found'
    body("/a").should == 'found'
  end

  it "does not modify behavior if body is not an array" do
    app(:bare) do
      plugin :not_found do
        "not found"
      end

      o = Object.new
      def o.join() '' end
      route do |r|
        r.halt [404, {}, o]
      end
    end

    body.should == ''
  end

  it "does not modify behavior if body is not an empty array" do
    app(:bare) do
      plugin :not_found do
        "not found"
      end

      route do |r|
        response.status = 404
        response.write 'a'
      end
    end

    body.should == 'a'
  end
end
