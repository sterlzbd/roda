require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "delay_build plugin" do 
  it "does not build rack app until app is called" do
    app(:delay_build){"a"}
    app.instance_variable_get(:@app).should == nil
    body.should == "a"
    app.instance_variable_get(:@app).should_not == nil
  end

  it "only rebuilds the app if build! is called" do
    app(:delay_build){"a"}
    body.should == "a"
    c = Class.new do
      def initialize(_) end
      def call(_) [200, {}, ["b"]] end
    end
    app.use c
    body.should == "a"
    app.build!
    body.should == "b"
  end
end
