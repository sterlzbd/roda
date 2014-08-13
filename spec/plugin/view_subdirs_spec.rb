require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

begin
  require 'tilt/erb'
rescue LoadError
  warn "tilt not installed, skipping view_subdirs plugin test"  
else
describe "view_subdirs plugin" do
  before do
    app(:bare) do
      plugin :render
      render_opts[:views] = "./spec"
      plugin :view_subdirs

      route do |r|
        r.on "home" do
          set_view_subdir 'views'
          view("home", :locals=>{:name => "Agent Smith", :title => "Home"}, :layout_opts=>{:locals=>{:title=>"Home"}})
        end

        r.on "about" do
          set_view_subdir 'views'
          render("views/about", :locals=>{:title => "About Roda"})
        end

        r.on "path" do
          render('views/about', :locals=>{:title => "Path"}, :layout_opts=>{:locals=>{:title=>"Home"}})
        end
      end
    end
  end

  it "should use set subdir if template name does not contain a slash" do
    body("/home").strip.should == "<title>Roda: Home</title>\n<h1>Home</h1>\n<p>Hello Agent Smith</p>"
  end

  it "should not use set subdir if template name contains a slash" do
    body("/about").strip.should == "<h1>About Roda</h1>"
  end

  it "should not change behavior when subdir is not set" do
    body("/path").strip.should == "<h1>Path</h1>"
  end
end
end
