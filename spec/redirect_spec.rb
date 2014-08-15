require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "redirects" do
  it "should be immediately processed" do
    app do |r|
      r.root do
        r.redirect "/hello"
        "Foo"
      end

      r.is "about" do
        r.redirect "/hello", 301
        "Foo"
      end

      r.is 'foo' do
        r.get do
          r.redirect
        end

        r.post do
          r.redirect
        end
      end
    end

    status.should == 302
    header('Location').should == '/hello'
    body.should == ''

    status("/about").should == 301
    header('Location', "/about").should == '/hello'
    body("/about").should == ''

    status("/foo", 'REQUEST_METHOD'=>'POST').should == 302
    header('Location', "/foo", 'REQUEST_METHOD'=>'POST').should == '/foo'
    body("/foo", 'REQUEST_METHOD'=>'POST').should == ''

    proc{req('/foo')}.should raise_error(Roda::RodaError)
  end
end
