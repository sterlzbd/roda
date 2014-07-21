require File.expand_path("helper", File.dirname(__FILE__))

describe "root/empty segment matching" do
  it "matching an empty segment" do
    app do |r|
      r.on "" do
        r.path
      end
    end

    body.should == '/'
    status("/foo").should == 404
  end

  it "nested empty segments" do
    app do |r|
      r.on "" do
        r.on "" do
          r.on "1" do
            r.path
          end
        end
      end
    end

    body("///1").should == '///1'
    status("/1").should == 404
    status("//1").should == 404
  end

  it "/events/? scenario" do
    a = app do |r|
      r.on :root=>true do
        "Hooray"
      end
    end

    app(:new) do |r|
      r.on "events" do
        r.run a
      end
    end

    body("/events").should == 'Hooray'
    body("/events/").should == 'Hooray'
    status("/events/foo").should == 404
  end
end
