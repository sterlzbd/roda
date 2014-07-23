require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "param matcher" do
  it "should yield a param only if given" do
    app do |r|
      r.get "signup", :param=>"email" do |email|
        email
      end

      r.on do
        "No email"
      end
    end

    io = StringIO.new
    body("/signup", "rack.input" => io, "QUERY_STRING" => "email=john@doe.com").should == 'john@doe.com'
    body("/signup", "rack.input" => io, "QUERY_STRING" => "").should == 'No email'
    body("/signup", "rack.input" => io, "QUERY_STRING" => "email=").should == ''
  end
end
