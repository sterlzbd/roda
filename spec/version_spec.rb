require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "Sinuba::VERSION" do
  it "should be in x.y.z integer format" do
    Sinuba::SinubaVersion.should =~ /\A\d+\.\d+\.\d+\z/
  end
end

