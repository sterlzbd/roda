require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "host matcher" do
  it "should match a host" do
    app do |r|
      r.on :host=>"example.com" do
        "worked"
      end
    end

    body("HTTP_HOST" => "example.com").should == 'worked'
    status("HTTP_HOST" => "foo.com").should == 404
  end

  it "should match a host with a regexp" do
    app do |r|
      r.on :host=>/example/ do
        "worked"
      end
    end

    body("HTTP_HOST" => "example.com").should == 'worked'
    status("HTTP_HOST" => "foo.com").should == 404
  end
end
