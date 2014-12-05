require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "environments plugin" do 
  before do
    app(:environments)
  end

  it "adds environment accessor for getting/setting the environment" do
    app.environment.should == :development
    app.environment = :test
    app.environment.should == :test
    
    app.plugin :environments, :production
    app.environment.should == :production
  end

  it "adds predicates for testing the environment" do
    app.development?.should == true
    app.test?.should == false
    app.production?.should == false
  end

  it "adds configure method which yields if no arguments are given or an environment matches" do
    a = []
    app.configure{a << 1}
    app.configure(:development){|ap| a << ap}
    app.configure(:test, :production){a << 2}
    a.should == [1, app]
  end
end
