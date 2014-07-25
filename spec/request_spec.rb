require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "request.full_path_info" do
  it "should return the script name and path_info as a string" do
    app do |r|
      r.on "foo" do
        "#{r.full_path_info}:#{r.script_name}:#{r.path_info}"
      end
    end

    body("/foo/bar").should ==  "/foo/bar:/foo:/bar"
  end
end
