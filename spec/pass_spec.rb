require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "pass plugin" do 
  it "executes on no arguments" do
    app(:pass) do |r|
      r.on :id do |id|
        pass if id == 'foo'
        id
      end

      r.on ":x/:y" do |x, y|
        x + y
      end
    end

    body("/a").should == 'a'
    body("/a/b").should == 'a'
    body("/foo/a").should == 'fooa'
    body("/foo/a/b").should == 'fooa'
    status("/foo").should == 404
    status.should == 404
  end
end
