require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "request verb methods" do 
  it "executes on true" do
    app do |r|
      r.get do
        "g"
      end
      r.post do
        "p"
      end
    end

    body.should == 'g'
    body('REQUEST_METHOD'=>'POST').should == 'p'
  end
end
