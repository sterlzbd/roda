require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "drop_body plugin" do 
  it "automatically drops body and Content-Type/Content-Length headers for responses without a body" do
    app(:drop_body) do |r|
      response.status = r.path.to_i
      response.write('a')
    end

    [101, 102, 204, 205, 304].each do  |i|
      body(i.to_s).should == ''
      header('Content-Type', i.to_s).should == nil
      header('Content-Length', i.to_s).should == nil
    end

    body('200').should == 'a'
    header('Content-Type', '200').should == 'text/html'
    header('Content-Length', '200').should == '1'
  end
end
