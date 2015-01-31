require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "error_handler plugin" do 
  it "executes only if error raised" do
    app(:bare) do
      plugin :error_handler

      error do |e|
        e.message
      end

      route do |r|
        r.on "a" do
          "found"
        end

        raise ArgumentError, "bad idea"
      end
    end

    body("/a").should == 'found'
    status("/a").should == 200
    body.should == 'bad idea'
    status.should == 500
  end

  it "executes on SyntaxError exceptions" do
    app(:bare) do
      plugin :error_handler

      error do |e|
        e.message
      end

      route do |r|
        r.on "a" do
          "found"
        end

        raise SyntaxError, 'bad idea'
      end
    end

    body("/a").should == 'found'
    status("/a").should == 200
    body.should == 'bad idea'
    status.should == 500
  end

  it "can override status inside error block" do
    app(:bare) do
      plugin :error_handler do |e|
        response.status = 501
        e.message
      end

      route do |r|
        raise ArgumentError, "bad idea"
      end
    end

    status.should == 501
  end

  it "calculates correct Content-Length" do
    app(:bare) do
      plugin :error_handler do |e|
        "a"
      end

      route do |r|
        raise ArgumentError, "bad idea"
      end
    end

    header('Content-Length').should == "1"
  end

  it "clears existing headers" do
    app(:bare) do
      plugin :error_handler do |e|
        "a"
      end

      route do |r|
        response['Content-Type'] = 'text/pdf'
        response['Foo'] = 'bar'
        raise ArgumentError, "bad idea"
      end
    end

    header('Content-Type').should == 'text/html'
    header('Foo').should == nil
  end

  it "can set error via the plugin block" do
    app(:bare) do
      plugin :error_handler do |e|
        e.message
      end

      route do |r|
        raise ArgumentError, "bad idea"
      end
    end

    body.should == 'bad idea'
  end

  it "has default error handler also raise" do
    app(:bare) do
      plugin :error_handler

      route do |r|
        raise ArgumentError, "bad idea"
      end
    end

    proc{req}.should raise_error(ArgumentError)
  end
end
