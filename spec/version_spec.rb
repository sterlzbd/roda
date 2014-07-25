require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "Roda::RodaVersion" do
  it "should be a string in x.y.z integer format" do
    Roda::RodaVersion.should =~ /\A\d+\.\d+\.\d+\z/
  end
end

