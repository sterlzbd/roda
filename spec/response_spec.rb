require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "cookie handling" do
  it "should set cookies on response" do
    app do |r|
      response.set_cookie("foo", "bar")
      response.set_cookie("bar", "baz")
      "Hello"
    end

    header('Set-Cookie').should == "foo=bar\nbar=baz"
    body.should == 'Hello'
  end

  it "should delete cookies on response" do
    app do |r|
      response.set_cookie("foo", "bar")
      response.delete_cookie("foo")
      "Hello"
    end

    header('Set-Cookie').should =~ /foo=; (max-age=0; )?expires=Thu, 01[ -]Jan[ -]1970 00:00:00 (-0000|GMT)/
    body.should == 'Hello'
  end
end

describe "response #[] and #[]=" do
  it "should get/set headers" do
    app do |r|
      response['foo'] = 'bar'
      response['foo'] + response.headers['foo']
    end

    header('foo').should == "bar"
    body.should == 'barbar'
  end
end

describe "response #write" do
  it "should add to body" do
    app do |r|
      response.write 'a'
      response.write 'b'
    end

    body.should == 'ab'
  end
end

describe "response #finish" do
  it "should set status to 404 if body has not been written to" do
    app do |r|
      s, h, b = response.finish
      "#{s}#{h['Content-Type']}#{b.length}"
    end

    body.should == '404text/html0'
  end

  it "should set status to 200 if body has been written to" do
    app do |r|
      response.write 'a'
      s, h, b = response.finish
      response.write "#{s}#{h['Content-Type']}#{b.length}"
    end

    body.should == 'a200text/html1'
  end

  it "should not overwrite existing status" do
    app do |r|
      response.status = 500
      s, h, b = response.finish
      "#{s}#{h['Content-Type']}#{b.length}"
    end

    body.should == '500text/html0'
  end
end

describe "response #redirect" do
  it "should set location and status" do
    app do |r|
      r.on 'a' do
        response.redirect '/foo', 303
      end
      r.on do
        response.redirect '/bar'
      end
    end

    status('/a').should == 303
    status.should == 302
    header('Location', '/a').should == '/foo'
    header('Location').should == '/bar'
  end
end

describe "response #empty?" do
  it "should return whether the body is empty" do
    app do |r|
      r.on 'a' do
        response['foo'] = response.empty?.to_s
      end
      r.on do
        response.write 'a'
        response['foo'] = response.empty?.to_s
      end
    end

    header('foo', '/a').should == 'true'
    header('foo').should == 'false'
  end
end
