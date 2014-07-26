require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "middleware plugin" do 
  it "turns Roda app into middlware" do
    a2 = app(:bare) do
      plugin :middleware

      route do |r|
        r.is "a" do
          "a2"
        end
        r.post "b" do
          "b2"
        end
      end
    end

    a3 = app(:bare) do
      plugin :middleware

      route do |r|
        r.get "a" do
          "a3"
        end
        r.get "b" do
          "b3"
        end
      end
    end

    app(:bare) do
      use a3
      use a2

      route do |r|
        r.is "a" do
          "a1"
        end
        r.is "b" do
          "b1"
        end
      end
    end

    body('/a').should == 'a3'
    body('/b').should == 'b3'
    body('/a', 'REQUEST_METHOD'=>'POST').should == 'a2'
    body('/b', 'REQUEST_METHOD'=>'POST').should == 'b2'
    body('/a', 'REQUEST_METHOD'=>'PATCH').should == 'a2'
    body('/b', 'REQUEST_METHOD'=>'PATCH').should == 'b1'
  end
end
