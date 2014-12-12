require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "static_path_info plugin" do 
  it "does not modify SCRIPT_NAME/PATH_INFO during routing" do
    app(:bare) do
      plugin :static_path_info
      plugin :pass

      route do |r|
        r.on "foo" do
          r.is "bar" do
            "bar|#{env['SCRIPT_NAME']}|#{env['PATH_INFO']}"
          end
          r.is "baz" do
            r.pass
          end
          "foo|#{env['SCRIPT_NAME']}|#{env['PATH_INFO']}"
        end
        "#{env['SCRIPT_NAME']}|#{env['PATH_INFO']}"
      end
    end

    body.should == '|/'
    body('SCRIPT_NAME'=>'/a').should == '/a|/'
    body('/foo').should == 'foo||/foo'
    body('/foo', 'SCRIPT_NAME'=>'/a').should == 'foo|/a|/foo'
    body('/foo/bar').should == 'bar||/foo/bar'
    body('/foo/bar', 'SCRIPT_NAME'=>'/a').should == 'bar|/a|/foo/bar'
    body('/foo/baz').should == 'foo||/foo/baz'
    body('/foo/baz', 'SCRIPT_NAME'=>'/a').should == 'foo|/a|/foo/baz'
  end

  it "modifies SCRIPT_NAME/PATH_INFO when calling run" do
    a = app{|r| "#{r.script_name}|#{r.path_info}"}
    app(:static_path_info){|r| r.on("a"){r.run a}}
    body("/a/b").should == "/a|/b"
  end
end
