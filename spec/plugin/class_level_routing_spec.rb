require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "class_level_routing plugin" do 
  before do
    app(:bare) do 
      plugin :class_level_routing
      plugin :all_verbs

      root do
        'root'
      end

      on "foo" do
        request.get "bar" do
          "foobar"
        end

        "foo"
      end

      is "d:d" do |x|
        request.get do
          "bazget#{x}"
        end

        request.post do
          "bazpost#{x}"
        end
      end

      meths = %w'get post delete head options patch put trace'
      meths.concat(%w'link unlink') if ::Rack::Request.method_defined?("link?")
      meths.each do |meth|
        send(meth, :d) do |m|
          "x-#{meth}-#{m}"
        end
      end
    end
  end

  it "adds class methods for setting up routes" do
    body.should == 'root'
    body('/foo').should == 'foo'
    body('/foo/bar').should == 'foobar'
    body('/dgo').should == 'bazgetgo'
    body('/dgo', 'REQUEST_METHOD'=>'POST').should == 'bazpostgo'
    body('/bar').should == "x-get-bar"
    body('/bar', 'REQUEST_METHOD'=>'POST').should == "x-post-bar"
    body('/bar', 'REQUEST_METHOD'=>'DELETE').should == "x-delete-bar"
    body('/bar', 'REQUEST_METHOD'=>'HEAD').should == "x-head-bar"
    body('/bar', 'REQUEST_METHOD'=>'OPTIONS').should == "x-options-bar"
    body('/bar', 'REQUEST_METHOD'=>'PATCH').should == "x-patch-bar"
    body('/bar', 'REQUEST_METHOD'=>'PUT').should == "x-put-bar"
    body('/bar', 'REQUEST_METHOD'=>'TRACE').should == "x-trace-bar"
    if ::Rack::Request.method_defined?("link?")
      body('/bar', 'REQUEST_METHOD'=>'LINK').should == "x-link-bar"
      body('/bar', 'REQUEST_METHOD'=>'UNLINK').should == "x-unlink-bar"
    end

    status.should == 200
    status("/asdfa/asdf").should == 404

    @app = Class.new(app)
    body.should == 'root'
    body('/foo').should == 'foo'
    body('/foo/bar').should == 'foobar'
    body('/dgo').should == 'bazgetgo'
    body('/dgo', 'REQUEST_METHOD'=>'POST').should == 'bazpostgo'
    body('/bar').should == "x-get-bar"
    body('/bar', 'REQUEST_METHOD'=>'POST').should == "x-post-bar"
    body('/bar', 'REQUEST_METHOD'=>'DELETE').should == "x-delete-bar"
    body('/bar', 'REQUEST_METHOD'=>'HEAD').should == "x-head-bar"
    body('/bar', 'REQUEST_METHOD'=>'OPTIONS').should == "x-options-bar"
    body('/bar', 'REQUEST_METHOD'=>'PATCH').should == "x-patch-bar"
    body('/bar', 'REQUEST_METHOD'=>'PUT').should == "x-put-bar"
    body('/bar', 'REQUEST_METHOD'=>'TRACE').should == "x-trace-bar"
  end

  it "only calls class level routes if routing tree doesn't handle request" do
    app.route do |r|
      r.root do
        'iroot'
      end

      r.get 'foo' do
        'ifoo'
      end

      r.on 'bar' do
        r.get true do
          response.status = 404
          ''
        end
        r.post true do
          'ibar'
        end
      end
    end

    body.should == 'iroot'
    body('/foo').should == 'ifoo'
    body('/foo/bar').should == 'foobar'
    body('/dgo').should == 'bazgetgo'
    body('/dgo', 'REQUEST_METHOD'=>'POST').should == 'bazpostgo'
    body('/bar').should == ""
    body('/bar', 'REQUEST_METHOD'=>'POST').should == "ibar"
    body('/bar', 'REQUEST_METHOD'=>'DELETE').should == "x-delete-bar"
    body('/bar', 'REQUEST_METHOD'=>'HEAD').should == "x-head-bar"
    body('/bar', 'REQUEST_METHOD'=>'OPTIONS').should == "x-options-bar"
    body('/bar', 'REQUEST_METHOD'=>'PATCH').should == "x-patch-bar"
    body('/bar', 'REQUEST_METHOD'=>'PUT').should == "x-put-bar"
    body('/bar', 'REQUEST_METHOD'=>'TRACE').should == "x-trace-bar"
  end

  it "works with the not_found plugin if loaded before" do
    app.plugin :not_found do
      "nf"
    end

    body.should == 'root'
    body('/foo').should == 'foo'
    body('/foo/bar').should == 'foobar'
    body('/dgo').should == 'bazgetgo'
    body('/dgo', 'REQUEST_METHOD'=>'POST').should == 'bazpostgo'
    body('/bar').should == "x-get-bar"
    body('/bar', 'REQUEST_METHOD'=>'POST').should == "x-post-bar"
    body('/bar', 'REQUEST_METHOD'=>'DELETE').should == "x-delete-bar"
    body('/bar', 'REQUEST_METHOD'=>'HEAD').should == "x-head-bar"
    body('/bar', 'REQUEST_METHOD'=>'OPTIONS').should == "x-options-bar"
    body('/bar', 'REQUEST_METHOD'=>'PATCH').should == "x-patch-bar"
    body('/bar', 'REQUEST_METHOD'=>'PUT').should == "x-put-bar"
    body('/bar', 'REQUEST_METHOD'=>'TRACE').should == "x-trace-bar"

    status.should == 200
    status("/asdfa/asdf").should == 404
    body("/asdfa/asdf").should == "nf"
  end
end
