require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "delegate plugin" do 
  it "adds request_delegate and response_delegate class methods for delegating" do
    app(:bare) do 
      plugin :delegate
      request_delegate :root
      response_delegate :headers

      route do
        root do
          headers['Content-Type'] = 'foo'
        end
      end
    end
    
    header('Content-Type').should == 'foo'
    status('/foo').should == 404
  end
end
