require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "Sinuba#env" do
  it "should return the environment" do
    app do |r|
      r.on do
        env['PATH_INFO']
      end
    end

    body("/foo").should ==  "/foo"
  end
end
