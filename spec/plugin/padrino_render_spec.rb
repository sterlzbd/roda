require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

begin
  require 'tilt/erb'
rescue LoadError
  warn "tilt not installed, skipping padrino_render plugin test"  
else
describe "padrino_render plugin" do
  before do
    app(:bare) do
      plugin :padrino_render, :views=>"./spec/views"

      route do |r|
        r.is "partial" do
          partial("test", :locals=>{:title => "About Roda"})
        end

        r.is "partial/subdir" do
          partial("about/test", :locals=>{:title => "About Roda"})
        end

        r.is "partial/inline" do
          partial(:inline=>"Hello <%= name %>", :locals=>{:name => "Agent Smith"})
        end

        r.is "render" do
          render(:content=>'bar', :layout_opts=>{:locals=>{:title=>"Home"}})
        end

        r.is "render/nolayout" do
          render("about", :locals=>{:title => "No Layout"}, :layout=>nil)
        end
      end
    end
  end

  it "partial renders without layout, and prepends _ to template" do
    body("/partial").strip.should == "<h1>About Roda</h1>"
  end

  it "partial renders without layout, and prepends _ to template" do
    body("/partial/subdir").strip.should == "<h1>Subdir: About Roda</h1>"
  end

  it "partial handles inline partials" do
    body("/partial/inline").strip.should == "Hello Agent Smith"
  end

  it "render uses layout by default" do
    body("/render").strip.should == "<title>Roda: Home</title>\nbar"
  end

  it "render doesn't use layout if layout is nil" do
    body("/render/nolayout").strip.should == "<h1>No Layout</h1>"
  end
end
end
