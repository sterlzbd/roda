require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

begin
  require 'tilt'
rescue LoadError
  warn "tilt not installed, skipping render plugin test"  
else
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
          render("about", :locals=>{:title => "About Roda"})
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
    body("/about").strip.should == "<h1>About Roda</h1>"
    body("/home").strip.should == "<title>Roda: Home</title>\n<h1>Home</h1>\n<p>Hello Agent Smith</p>"
    body("/inline").strip.should == "Hello Agent Smith"
    body("/path").strip.should == "<h1>Path</h1>"
  end

  it "with str as engine" do
    app.render_opts[:engine] = "str"
    body("/about").strip.should == "<h1>About Roda</h1>"
    body("/home").strip.should == "<title>Roda: Home</title>\n<h1>Home</h1>\n<p>Hello Agent Smith</p>"
    body("/inline").strip.should == "Hello <%= name %>"
  end

  it "with str as ext" do
    app.render_opts[:ext] = "str"
    body("/about").strip.should == "<h1>About Roda</h1>"
    body("/home").strip.should == "<title>Roda: Home</title>\n<h1>Home</h1>\n<p>Hello Agent Smith</p>"
    body("/inline").strip.should == "Hello Agent Smith"
  end

  it "custom default layout support" do
    app.render_opts[:layout] = "layout-alternative"
    body("/home").strip.should == "<title>Alternative Layout: Home</title>\n<h1>Home</h1>\n<p>Hello Agent Smith</p>"
  end
end

describe "render plugin" do
  it "simple layout support" do
    app(:bare) do
      plugin :render
      
      route do |r|
        render(:path=>"spec/views/layout-yield.erb") do
          render(:path=>"spec/views/content-yield.erb")
        end
      end
    end

    body.gsub(/\n+/, "\n").should == "Header\nThis is the actual content.\nFooter\n"
  end

  it "layout overrides" do
    app(:bare) do
      plugin :render, :views=>"./spec/views"
      
      route do |r|
        view("home", :locals=>{:name=>"Agent Smith", :title=>"Home" }, :layout=>"layout-alternative", :layout_opts=>{:locals=>{:title=>"Home"}})
      end
    end

    body.strip.should == "<title>Alternative Layout: Home</title>\n<h1>Home</h1>\n<p>Hello Agent Smith</p>"
  end

  it "inline layouts and inline views" do
    app(:render) do
      view({:inline=>'bar'}, :layout=>{:inline=>'Foo: <%= yield %>'})
    end

    body.strip.should == "Foo: bar"
  end

  it "inline renders with opts" do
    app(:render) do
      render({:inline=>'<%= bar %>'}, {:engine=>'str'})
    end

    body.strip.should == '<%= bar %>'
  end

  it "render_opts inheritance" do
    c = Class.new(Roda)
    c.plugin :render
    sc = Class.new(c)

    c.render_opts.should_not equal(sc.render_opts)
    c.render_opts[:layout_opts].should_not equal(sc.render_opts[:layout_opts])
    c.render_opts[:opts].should_not equal(sc.render_opts[:opts])
    c.render_opts[:cache].should_not equal(sc.render_opts[:cache])
  end

  it "with caching disabled" do
    app(:bare) do
      plugin :render, :views=>"./spec/views", :cache=>false
      
      route do |r|
        view(:inline=>"Hello <%= name %>: <%= render_opts[:cache] %>", :locals=>{:name => "Agent Smith"}, :layout=>nil)
      end
    end

    body("/inline").strip.should == "Hello Agent Smith: false"

    Class.new(app).render_opts[:cache].should == false
  end
end
end
