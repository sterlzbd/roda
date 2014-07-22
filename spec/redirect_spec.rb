require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "redirects" do
  it "should be immediately processed" do
    app do |r|
      r.on "about" do
        r.redirect "/hello", 301
        "Foo"
      end
      r.on true do
        r.redirect "/hello"
        "Foo"
      end
    end

    status.should == 302
    header('Location').should == '/hello'
    body.should == ''

    status("/about").should == 301
    header('Location', "/about").should == '/hello'
    body("/about").should == ''
  end
end
