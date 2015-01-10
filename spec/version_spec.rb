require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "Roda version constants" do
  it "RodaVersion should be a string in x.y.z integer format" do
    Roda::RodaVersion.should =~ /\A\d+\.\d+\.\d+\z/
  end

  it "Roda*Version should be integers" do
    Roda::RodaMajorVersion.should be_a_kind_of(Integer)
    Roda::RodaMinorVersion.should be_a_kind_of(Integer)
    Roda::RodaPatchVersion.should be_a_kind_of(Integer)
  end
end

