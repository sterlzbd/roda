require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "path matchers" do 
  it "one level path" do
    app do |r|
      r.on "about" do
        "About"
      end
    end

    body('/about').should == "About"
    status("/abot").should == 404
  end

  it "two level nested paths" do
    app do |r|
      r.on "about" do
        r.on "1" do
          "+1"
        end

        r.on "2" do
          "+2"
        end
      end
    end

    body('/about/1').should == "+1"
    body('/about/2').should == "+2"
    status('/about/3').should == 404
  end

  it "two level inlined paths" do
    app do |r|
      r.on "a/b" do
        "ab"
      end
    end

    body('/a/b').should == "ab"
    status('/a/d').should == 404
  end

  it "a path with some regex captures" do
    app do |r|
      r.on "user(\\d+)" do |uid|
        uid
      end
    end

    body('/user123').should == "123"
    status('/useradf').should == 404
  end

  it "matching the root" do
    app do |r|
      r.on "" do
        "Home"
      end
    end

    body.should == 'Home'
    status("/foo").should == 404
  end
end
