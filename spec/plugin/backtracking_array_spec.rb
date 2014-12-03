require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "backtracking_array plugin" do 
  it "backtracks to next entry in array if later matcher fails" do
    app(:backtracking_array) do |r|
      r.is %w'a a/b' do |id|
        id
      end

      r.is %w'c c/d', %w'd e' do |a, b|
        "#{a}-#{b}" 
      end

      r.is [%w'f f/g', %w'g g/h'] do |id|
        id
      end
    end

    tests = lambda do
      status.should == 404

      body("/a").should == 'a'
      body("/a/b").should == 'a/b'
      status("/a/b/").should == 404

      body("/c/d").should == 'c-d'
      body("/c/e").should == 'c-e'
      body("/c/d/d").should == 'c/d-d'
      body("/c/d/e").should == 'c/d-e'
      status("/c/d/").should == 404

      body("/f").should == 'f'
      body("/f/g").should == 'f/g'
      body("/g").should == 'g'
      body("/g/h").should == 'g/h'
      status("/f/g/").should == 404
      status("/g/h/").should == 404
    end

    tests.call
    app.plugin(:static_path_info)
    tests.call
  end
end
