require File.expand_path("helper", File.dirname(__FILE__))

describe "extension matcher" do
  it "should match given file extensions" do
    app do |r|
      r.on "styles" do
        r.on :extension=>"css" do |file|
          file
        end
      end
    end

    body("/styles/reset.css").should == 'reset'
    status("/styles/reset.bar").should == 404
  end
end
