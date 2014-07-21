require File.expand_path("helper", File.dirname(__FILE__))

describe "cookie handling" do
  it "should set cookies on response" do
    app do |r|
      r.on true do
        response.set_cookie("foo", "bar")
        response.set_cookie("bar", "baz")
        "Hello"
      end
    end

    header('Set-Cookie').should == "foo=bar\nbar=baz"
    body.should == 'Hello'
  end

  it "should delete cookies on response" do
    app do |r|
      r.on true do
        response.set_cookie("foo", "bar")
        response.delete_cookie("foo")
        "Hello"
      end
    end

    header('Set-Cookie').should =~ /foo=; (max-age=0; )?expires=Thu, 01[ -]Jan[ -]1970 00:00:00 (-0000|GMT)/
    body.should == 'Hello'
  end
end
