require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "r.is" do 
  it "ensures the patch is matched fully" do
    app do |r|
      r.is "" do
        "+1"
      end
    end

    body.should == '+1'
    status('//').should == 404
  end

  it "handles no arguments" do
    app do |r|
      r.on "" do
        r.is do
          "+1"
        end
      end
    end

    body.should == '+1'
    status('//').should == 404
  end

  it "matches strings" do
    app do |r|
      r.is "123" do
        "+1"
      end
    end

    body("/123").should == '+1'
    status("/123/").should == 404
  end

  it "matches regexps" do
    app do |r|
      r.is /(\w+)/ do |id|
        id
      end
    end

    body("/123").should == '123'
    status("/123/").should == 404
  end

  it "matches segments" do
    app do |r|
      r.is :id do |id|
        id
      end
    end

    body("/123").should == '123'
    status("/123/").should == 404
  end
end

