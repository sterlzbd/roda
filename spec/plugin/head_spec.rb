require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "head plugin" do 
  it "considers HEAD requests as GET requests which return no body" do
    app(:head) do |r|
      r.root do
        'root'
      end

      r.get 'a' do
        'a'
      end

      r.is 'b', :method=>[:get, :post] do
        'b'
      end
    end

    s, h, b = req
    s.should == 200
    h['Content-Length'].should == '4'
    b.should == ['root']

    s, h, b = req('REQUEST_METHOD' => 'HEAD')
    s.should == 200
    h['Content-Length'].should == '4'
    b.should == []

    body('/a').should == 'a'
    status('/a', 'REQUEST_METHOD' => 'HEAD').should == 200

    body('/b').should == 'b'
    status('/b', 'REQUEST_METHOD' => 'HEAD').should == 200
  end
end
