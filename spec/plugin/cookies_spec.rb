require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "cookies plugin" do 
  it "should set cookies on response" do
    app(:cookies) do |r|
      response.set_cookie("foo", "bar")
      response.set_cookie("bar", "baz")
      "Hello"
    end

    header('Set-Cookie').must_equal "foo=bar\nbar=baz"
    body.must_equal 'Hello'
  end

  it "should delete cookies on response" do
    app(:cookies) do |r|
      response.set_cookie("foo", "bar")
      response.delete_cookie("foo")
      "Hello"
    end

    header('Set-Cookie').must_match /foo=; (max-age=0; )?expires=Thu, 01[ -]Jan[ -]1970 00:00:00 (-0000|GMT)/
    body.must_equal 'Hello'
  end
end
