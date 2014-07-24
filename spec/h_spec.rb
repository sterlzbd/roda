require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "h plugin" do 
  it "adds h method for html escaping" do
    app(:h) do |r|
      r.on do |id|
        h("<form>") + h(:form)
      end
    end

    body.should == '&lt;form&gt;form'
  end
end
