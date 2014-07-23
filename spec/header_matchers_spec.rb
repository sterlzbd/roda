require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "accept matcher" do
  it "should accept mimetypes and set response Content-Type" do
    app(:header_matchers) do |r|
      r.on :accept=>"application/xml" do
        response["Content-Type"]
      end
    end

    body("HTTP_ACCEPT" => "application/xml").should ==  "application/xml"
    status.should == 404
  end
end

describe "header matcher" do
  it "should match if header present" do
    app(:header_matchers) do |r|
      r.on :header=>"http-accept" do
        "bar"
      end
    end

    body("HTTP_ACCEPT" => "application/xml").should ==  "bar"
    status.should == 404
  end
end

describe "host matcher" do
  it "should match a host" do
    app(:header_matchers) do |r|
      r.on :host=>"example.com" do
        "worked"
      end
    end

    body("HTTP_HOST" => "example.com").should == 'worked'
    status("HTTP_HOST" => "foo.com").should == 404
  end

  it "should match a host with a regexp" do
    app(:header_matchers) do |r|
      r.on :host=>/example/ do
        "worked"
      end
    end

    body("HTTP_HOST" => "example.com").should == 'worked'
    status("HTTP_HOST" => "foo.com").should == 404
  end

  it "doesn't yield HOST" do
    app(:header_matchers) do |r|
      r.on :host=>"example.com" do |*args|
        args.size.to_s
      end
    end

    body("HTTP_HOST" => "example.com").should == '0'
  end
end
