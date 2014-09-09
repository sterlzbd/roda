require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "path plugin" do 
  it "adds path method for defining named paths" do
    app(:bare) do
      plugin :path
      path :foo, "/foo"
      path :bar do |o|
        "/bar/#{o}"
      end

      route do |r|
        "#{foo_path}#{bar_path('a')}"
      end
    end

    body.should == '/foo/bar/a'
  end

  it "raises if both path and block are given" do
    app.plugin :path
    proc{app.path(:foo, '/foo'){}}.should raise_error(Roda::RodaError)
  end

  it "raises if neither path nor block are given" do
    app.plugin :path
    proc{app.path(:foo)}.should raise_error(Roda::RodaError)
  end
end
