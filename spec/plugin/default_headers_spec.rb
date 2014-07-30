require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "default_headers plugin" do 
  it "sets the default headers to use for the response" do
    h = {'Content-Type'=>'text/json', 'Foo'=>'bar'}

    app(:bare) do
      plugin :default_headers, h
      route do |r|
      end
    end

    req[1].should == h
    req[1].should_not equal(h)
  end

  it "should not override existing default headers" do
    h = {'Content-Type'=>'text/json', 'Foo'=>'bar'}

    app(:bare) do
      plugin :default_headers, h
      plugin :default_headers

      route do |r|
      end
    end

    req[1].should == h
  end

  it "should allow modifying the default headers at a later point" do
    h = {'Content-Type'=>'text/json', 'Foo'=>'bar'}

    app(:bare) do
      plugin :default_headers
      default_headers['Content-Type'] = 'text/json'
      default_headers['Foo'] = 'bar'

      route do |r|
      end
    end

    req[1].should == h
  end

  it "should work correctly in subclasses" do
    h = {'Content-Type'=>'text/json', 'Foo'=>'bar'}

    app(:bare) do
      plugin :default_headers
      default_headers['Content-Type'] = 'text/json'
      default_headers['Foo'] = 'bar'

      route do |r|
      end
    end

    @app = Class.new(@app)
    @app.route{}

    req[1].should == h
  end
end
