require File.expand_path("spec_helper", File.dirname(__FILE__))
require "stringio"

describe "param matcher" do
  it "should yield a param only if not empty" do
    app do |r|
      r.get "signup", :param=>"email" do |email|
        email
      end

      r.on true do
        "No email"
      end
    end

    io = StringIO.new
    body("/signup", "rack.input" => io, "QUERY_STRING" => "email=john@doe.com").should == 'john@doe.com'
    body("/signup", "rack.input" => io, "QUERY_STRING" => "").should == 'No email'
    body("/signup", "rack.input" => io, "QUERY_STRING" => "email=").should == 'No email'
  end
end
