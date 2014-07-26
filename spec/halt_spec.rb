require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "halt plugin" do
  it "should still have halt return rack response as argument given it as argument" do
    app(:halt) do |r|
      r.halt [200, {}, ['foo']]
    end

    body.should ==  "foo"
  end

  it "should consider string argument as response body" do
    app(:halt) do |r|
      r.halt "foo"
    end

    body.should ==  "foo"
  end

  it "should consider integer argument as response status" do
    app(:halt) do |r|
      r.halt 300
    end

    status.should == 300 
  end

  it "should consider 2 arguments as response status and body" do
    app(:halt) do |r|
      r.halt 300, "foo"
    end

    status.should == 300 
    body.should == "foo"
  end

  it "should consider 3 arguments as response" do
    app(:halt) do |r|
      r.halt 300, {'a'=>'b'}, "foo"
    end

    status.should == 300 
    header('a').should == 'b'
    body.should == "foo"
  end

  it "should raise an error for too many arguments" do
    app(:halt) do |r|
      r.halt 300, {'a'=>'b'}, "foo", 1
    end

    proc{req}.should raise_error(Roda::RodaError)
  end

  it "should raise an error for single argument not integer, String, or Array" do
    app(:halt) do |r|
      r.halt('a'=>'b')
    end

    proc{req}.should raise_error(Roda::RodaError)
  end
end
