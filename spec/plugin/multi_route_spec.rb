require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "multi_route plugin" do 
  before do
    app(:bare) do
      plugin :multi_route

      route(:get) do |r|
        r.is "" do
          "get"
        end
        
        r.is "a" do
          "geta"
        end
      end

      route(:post) do |r|
        r.is "" do
          "post"
        end
        
        r.is "a" do
          "posta"
        end
      end

      route do |r|
        r.get do
          route(:get)

          r.is "b" do
            "getb"
          end
        end
        r.post do
          route(:post)

          r.is "b" do
            "postb"
          end
        end
      end
    end
  end

  it "adds named routing support" do
    body.should == 'get'
    body('REQUEST_METHOD'=>'POST').should == 'post'
    body('/a').should == 'geta'
    body('/a', 'REQUEST_METHOD'=>'POST').should == 'posta'
    body('/b').should == 'getb'
    body('/b', 'REQUEST_METHOD'=>'POST').should == 'postb'
    status('/c').should == 404
    status('/c', 'REQUEST_METHOD'=>'POST').should == 404
  end

  it "handles loading the plugin multiple times correctly" do
    app.plugin :multi_route
    body.should == 'get'
    body('REQUEST_METHOD'=>'POST').should == 'post'
    body('/a').should == 'geta'
    body('/a', 'REQUEST_METHOD'=>'POST').should == 'posta'
    body('/b').should == 'getb'
    body('/b', 'REQUEST_METHOD'=>'POST').should == 'postb'
    status('/c').should == 404
    status('/c', 'REQUEST_METHOD'=>'POST').should == 404
  end

  it "handles subclassing correctly" do
    @app = Class.new(@app)
    @app.route do |r|
      r.get do
        route(:post)

        r.is "b" do
          "1b"
        end
      end
      r.post do
        route(:get)

        r.is "b" do
          "2b"
        end
      end
    end

    body.should == 'post'
    body('REQUEST_METHOD'=>'POST').should == 'get'
    body('/a').should == 'posta'
    body('/a', 'REQUEST_METHOD'=>'POST').should == 'geta'
    body('/b').should == '1b'
    body('/b', 'REQUEST_METHOD'=>'POST').should == '2b'
    status('/c').should == 404
    status('/c', 'REQUEST_METHOD'=>'POST').should == 404
  end
end
