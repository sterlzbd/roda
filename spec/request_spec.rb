require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "request.full_path_info" do
  it "should return the script name and path_info as a string" do
    app do |r|
      r.on "foo" do
        "#{r.full_path_info}:#{r.script_name}:#{r.path_info}"
      end
    end

    body("/foo/bar").should ==  "/foo/bar:/foo:/bar"
  end
end

describe "request.halt" do
  it "should return rack response as argument given it as argument" do
    app do |r|
      r.halt [200, {}, ['foo']]
    end

    body.should ==  "foo"
  end

  it "should consider string argument as response body" do
    app do |r|
      r.halt "foo"
    end

    body.should ==  "foo"
  end

  it "should consider integer argument as response status" do
    app do |r|
      r.halt 300
    end

    status.should == 300 
  end

  it "should consider 2 arguments as response status and body" do
    app do |r|
      r.halt 300, "foo"
    end

    status.should == 300 
    body.should == "foo"
  end

  it "should consider 3 arguments as response" do
    app do |r|
      r.halt 300, {'a'=>'b'}, "foo"
    end

    status.should == 300 
    header('a').should == 'b'
    body.should == "foo"
  end

  it "should raise an error for too many arguments" do
    app do |r|
      r.halt 300, {'a'=>'b'}, "foo", 1
    end

    proc{req}.should raise_error(Roda::RodaError)
  end

  it "should raise an error for single argument not integer, String, or Array" do
    app do |r|
      r.halt('a'=>'b')
    end

    proc{req}.should raise_error(Roda::RodaError)
  end
end
