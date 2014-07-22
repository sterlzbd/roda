require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "r.on" do 
  it "executes on no arguments" do
    app do |r|
      r.on do
        "+1"
      end
    end

    body.should == '+1'
  end

  it "executes on true" do
    app do |r|
      r.on true do
        "+1"
      end
    end

    body.should == '+1'
  end

  it "executes on non-false" do
    app do |r|
      r.on "123" do
        "+1"
      end
    end

    body("/123").should == '+1'
  end

  it "ensures SCRIPT_NAME and PATH_INFO are reverted" do
    app do |r|
      r.on lambda { r.env["SCRIPT_NAME"] = "/hello"; false } do
        "Unreachable"
      end
      
      r.on do
        r.env["SCRIPT_NAME"] + ':' + r.env["PATH_INFO"]
      end
    end

    body("/hello").should == ':/hello'
  end

  it "skips consecutive matches" do
    app do |r|
      r.on do
        "foo"
      end

      r.on do
        "bar"
      end
    end

    body.should == "foo"
  end

  it "finds first match available" do
    app do |r|
      r.on false do
        "foo"
      end

      r.on do
        "bar"
      end
    end

    body.should == "bar"
  end

  it "reverts a half-met matcher" do
    app do |r|
      r.on "post", false do
        "Should be unmet"
      end

      r.on do
        r.env["SCRIPT_NAME"] + ':' + r.env["PATH_INFO"]
      end
    end

    body("/hello").should == ':/hello'
  end
end
