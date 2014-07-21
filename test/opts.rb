require File.expand_path("helper", File.dirname(__FILE__))

describe "opts" do
  it "is inheritable and allows overriding" do
    c = Class.new(Sinuba)
    c.opts[:foo] = "bar"
    c.opts[:foo].should == "bar"

    sc = Class.new(c)
    sc.opts[:foo].should == "bar"

    sc.opts[:foo] = "baz"
    sc.opts[:foo].should == "baz"
    c.opts[:foo].should == "bar"
  end

  it "should be available as an instance methods" do
    app(:bare) do
      opts[:hello] = "Hello World"

      route do |r|
        r.on true do
          opts[:hello]
        end
      end
    end

    body.should == "Hello World"
  end

  it "should only shallow clone by default" do
    c = Class.new(Sinuba)
    c.opts[:foo] = "bar"
    c.opts[:foo].should == "bar"

    sc = Class.new(c)
    sc.opts[:foo].replace("baz")

    sc.opts[:foo].should == "baz"
    c.opts[:foo].should == "baz"
  end
end
