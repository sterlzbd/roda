require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "multi_run plugin" do 
  it "adds Roda.run method for setting up prefix delegations to other rack apps" do
    app(:multi_run) do |r|
      r.multi_run
      "c"
    end

    body("/a").should == 'c'
    body("/b").should == 'c'
    body("/b/a").should == 'c'
    body.should == 'c'

    app.run "a", Class.new(Roda).class_eval{route{"a1"}; app}

    body("/a").should == 'a1'
    body("/b").should == 'c'
    body("/b/a").should == 'c'
    body.should == 'c'

    app.run "b", Class.new(Roda).class_eval{route{"b1"}; app}

    body("/a").should == 'a1'
    body("/b").should == 'b1'
    body("/b/a").should == 'b1'
    body.should == 'c'

    app.run "b/a", Class.new(Roda).class_eval{route{"b2"}; app}

    body("/a").should == 'a1'
    body("/b").should == 'b1'
    body("/b/a").should == 'b2'
    body.should == 'c'
  end
end
