require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "all_verbs plugin" do 
  it "adds method for each http verb" do
    app(:all_verbs) do |r|
      r.delete{'d'}
      r.head{'h'}
      r.options{'o'}
      r.patch{'pa'}
      r.put{'pu'}
      r.trace{'t'}
      if Rack::Request.method_defined?(:link?)
        r.link{'l'}
        r.unlink{'u'}
      end
    end

    body('REQUEST_METHOD'=>'DELETE').should == 'd'
    body('REQUEST_METHOD'=>'HEAD').should == 'h'
    body('REQUEST_METHOD'=>'OPTIONS').should == 'o'
    body('REQUEST_METHOD'=>'PATCH').should == 'pa'
    body('REQUEST_METHOD'=>'PUT').should == 'pu'
    body('REQUEST_METHOD'=>'TRACE').should == 't'
    if Rack::Request.method_defined?(:link?)
      body('REQUEST_METHOD'=>'LINK').should == 'l'
      body('REQUEST_METHOD'=>'UNLINK').should == 'u'
    end
  end
end
