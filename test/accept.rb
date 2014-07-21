require File.expand_path("helper", File.dirname(__FILE__))

describe "accept matcher" do
  it "should accept mimetypes" do
    app do |r|
      r.on :accept=>"application/xml" do
        response["Content-Type"]
      end
    end

    body("HTTP_ACCEPT" => "application/xml").should ==  "application/xml"
    status.should == 404
  end
end
