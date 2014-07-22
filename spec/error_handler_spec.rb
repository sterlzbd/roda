require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "error_handler plugin" do 
  it "executes only if error raised" do
    app(:bare) do
      plugin :error_handler

      error do |e|
        e.message
      end

      route do |r|
        r.on "a" do
          "found"
        end

        raise ArgumentError, "bad idea"
      end
    end

    body("/a").should == 'found'
    body.should == 'bad idea'
  end

  it "can set error via the plugin block" do
    app(:bare) do
      plugin :error_handler do |e|
        e.message
      end

      route do |r|
        raise ArgumentError, "bad idea"
      end
    end

    body.should == 'bad idea'
  end
end
