require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "r.run" do
  it "should allow composition of apps" do
    a = app do |r|
      r.on "services/:id" do |id|
        "View #{id}"
      end
    end

    app(:new) do |r|
      r.on "provider" do
        r.run a
      end
    end

    body("/provider/services/101").should == 'View 101'
  end
end
