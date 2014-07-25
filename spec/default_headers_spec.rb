require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "default_headers plugin" do 
  it "sets the default headers to use for the response" do
    h = {'Content-Type'=>'text/json', 'Foo'=>'bar'}

    app(:bare) do
      plugin :default_headers, h
      route do |r|
      end
    end

    req[1].should == h
    req[1].should_not equal(h)
  end
end
