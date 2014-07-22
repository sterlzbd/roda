require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "render plugin" do
  before do
    app(:bare) do
      plugin :render
      render_opts[:views] = "./spec/views"

      route do |r|
        r.on "home" do
          view("home", :locals=>{:name => "Agent Smith", :title => "Home"}, :layout_opts=>{:locals=>{:title=>"Home"}})
        end

        r.on "about" do
          render("about", :locals=>{:title => "About Sinuba"})
        end

        r.on "inline" do
          view(:inline=>"Hello <%= name %>", :locals=>{:name => "Agent Smith"}, :layout=>nil)
        end

        r.on "path" do
          render(:path=>"./spec/views/about.erb", :locals=>{:title => "Path"}, :layout_opts=>{:locals=>{:title=>"Home"}})
        end
      end
    end
  end

  it "default actions" do
    body("/about").strip.should == "<h1>About Sinuba</h1>"
    body("/home").strip.should == "<title>Sinuba: Home</title>\n<h1>Home</h1>\n<p>Hello Agent Smith</p>"
    body("/inline").strip.should == "Hello Agent Smith"
    body("/path").strip.should == "<h1>Path</h1>"
  end

  it "with str as engine" do
    app.render_opts[:engine] = "str"
    body("/about").strip.should == "<h1>About Sinuba</h1>"
    body("/home").strip.should == "<title>Sinuba: Home</title>\n<h1>Home</h1>\n<p>Hello Agent Smith</p>"
  end

  it "custom default layout support" do
    app.render_opts[:layout] = "layout-alternative"
    body("/home").strip.should == "<title>Alternative Layout: Home</title>\n<h1>Home</h1>\n<p>Hello Agent Smith</p>"
  end
end

describe "render plugin layouts" do
  it "simple layout support" do
    app(:bare) do
      plugin :render
      
      route do |r|
        r.on true do
          render(:path=>"spec/views/layout-yield.erb") do
            render(:path=>"spec/views/content-yield.erb")
          end
        end
      end
    end

    body.gsub(/\n+/, "\n").should == "Header\nThis is the actual content.\nFooter\n"
  end

  it "layout overrides" do
    app(:bare) do
      plugin :render, :views=>"./spec/views"
      
      route do |r|
        r.on true do
          view("home", :locals=>{:name=>"Agent Smith", :title=>"Home" }, :layout=>"layout-alternative", :layout_opts=>{:locals=>{:title=>"Home"}})
        end
      end
    end

    body.strip.should == "<title>Alternative Layout: Home</title>\n<h1>Home</h1>\n<p>Hello Agent Smith</p>"
  end
end
