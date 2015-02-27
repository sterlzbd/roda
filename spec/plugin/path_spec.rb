require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "path plugin" do 
  def path_app(*args, &block)
    app(:bare) do
      plugin :path
      path *args, &block
      route{|r| send(r.path_info)}
    end
  end

  def path_script_name_app(*args, &block)
    app(:bare) do
      opts[:add_script_name] = true
      plugin :path
      path *args, &block
      route{|r| send(r.path_info)}
    end
  end

  def path_block_app(b, *args, &block)
    path_app(*args, &block)
    app.route{|r| send(r.path_info, &b)}
  end

  it "adds path method for defining named paths" do
    app(:bare) do
      plugin :path
      path :foo, "/foo"
      path :bar do |o|
        "/bar/#{o}"
      end
      path :baz do |&block|
        "/baz/#{block.call}"
      end

      route do |r|
        "#{foo_path}#{bar_path('a')}#{baz_path{'b'}}"
      end
    end

    body.should == '/foo/bar/a/baz/b'
  end

  it "raises if both path and block are given" do
    app.plugin :path
    proc{app.path(:foo, '/foo'){}}.should raise_error(Roda::RodaError)
  end

  it "raises if neither path nor block are given" do
    app.plugin :path
    proc{app.path(:foo)}.should raise_error(Roda::RodaError)
  end

  it "raises if two options hashes are given" do
    app.plugin :path
    proc{app.path(:foo, {:name=>'a'}, :add_script_name=>true)}.should raise_error(Roda::RodaError)
  end

  it "supports :name option for naming the method" do
    path_app(:foo, :name=>'foobar_route'){"/bar/foo"}
    body("foobar_route").should == "/bar/foo"
  end

  it "supports :add_script_name option for automatically adding the script name" do
    path_app(:foo, :add_script_name=>true){"/bar/foo"}
    body("foo_path", 'SCRIPT_NAME'=>'/baz').should == "/baz/bar/foo"
  end

  it "respects :add_script_name app option for automatically adding the script name" do
    path_script_name_app(:foo){"/bar/foo"}
    body("foo_path", 'SCRIPT_NAME'=>'/baz').should == "/baz/bar/foo"
  end

  it "supports :add_script_name=>false option for not automatically adding the script name" do
    path_script_name_app(:foo, :add_script_name=>false){"/bar/foo"}
    body("foo_path", 'SCRIPT_NAME'=>'/baz').should == "/bar/foo"
  end

  it "supports path method accepting a block when using :add_script_name" do
    path_block_app(lambda{"c"}, :foo, :add_script_name=>true){|&block| "/bar/foo/#{block.call}"}
    body("foo_path", 'SCRIPT_NAME'=>'/baz').should == "/baz/bar/foo/c"
  end

  it "supports :url option for also creating a *_url method" do
    path_app(:foo, :url=>true){"/bar/foo"}
    body("foo_path", 'HTTP_HOST'=>'example.org', "rack.url_scheme"=>'http', 'SERVER_PORT'=>80).should == "/bar/foo"
    body("foo_url", 'HTTP_HOST'=>'example.org', "rack.url_scheme"=>'http', 'SERVER_PORT'=>80).should == "http://example.org/bar/foo"
  end

  it "supports url method accepting a block when using :url" do
    path_block_app(lambda{"c"}, :foo, :url=>true){|&block| "/bar/foo/#{block.call}"}
    body("foo_url", 'HTTP_HOST'=>'example.org', "rack.url_scheme"=>'http', 'SERVER_PORT'=>80).should == "http://example.org/bar/foo/c"
  end

  it "supports url method name specified in :url option" do
    path_app(:foo, :url=>:foobar_uri){"/bar/foo"}
    body("foo_path", 'HTTP_HOST'=>'example.org', "rack.url_scheme"=>'http', 'SERVER_PORT'=>80).should == "/bar/foo"
    body("foobar_uri", 'HTTP_HOST'=>'example.org', "rack.url_scheme"=>'http', 'SERVER_PORT'=>80).should == "http://example.org/bar/foo"
  end

  it "supports :url_only option for not creating a path method" do
    path_app(:foo, :url_only=>true){"/bar/foo"}
    proc{body("foo_path")}.should raise_error(NoMethodError)
    body("foo_url", 'HTTP_HOST'=>'example.org', "rack.url_scheme"=>'http', 'SERVER_PORT'=>80).should == "http://example.org/bar/foo"
  end

  it "handles non-default ports in url methods" do
    path_app(:foo, :url=>true){"/bar/foo"}
    body("foo_url", 'HTTP_HOST'=>'example.org', "rack.url_scheme"=>'http', 'SERVER_PORT'=>81).should == "http://example.org:81/bar/foo"
  end
end
