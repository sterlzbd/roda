require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "slash_path_empty" do 
  it "considers a / path as empty" do
    app(:slash_path_empty) do |r|
      r.is{"1"}
      r.is("a"){"2"}
      r.get("b"){"3"}
    end

    body("").should == '1'
    body.should == '1'
    body("a").should == ''
    body("/a").should == '2'
    body("/a/").should == '2'
    body("/a/b").should == ''
    body("b").should == ''
    body("/b").should == '3'
    body("/b/").should == '3'
    body("/b/c").should == ''
  end
end
