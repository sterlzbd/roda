require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

begin
  require 'tilt/erb'
  require 'tilt/string'
rescue LoadError
  warn "tilt not installed, skipping render plugin test"  
else
describe "render plugin" do
  before do
    app(:bare) do
      plugin :render, :views=>"./spec/views"

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

        r.on "content" do
          view(:content=>'bar', :layout_opts=>{:locals=>{:title=>"Home"}})
        end
      end
    end
  end

  it "default actions" do
    body("/about").strip.should == "<h1>About Roda</h1>"
    body("/home").strip.should == "<title>Roda: Home</title>\n<h1>Home</h1>\n<p>Hello Agent Smith</p>"
    body("/inline").strip.should == "Hello Agent Smith"
    body("/path").strip.should == "<h1>Path</h1>"
    body("/content").strip.should == "<title>Roda: Home</title>\nbar"
  end

  it "with str as engine" do
    app.plugin :render, :engine => "str"
    body("/about").strip.should == "<h1>About Roda</h1>"
    body("/home").strip.should == "<title>Roda: Home</title>\n<h1>Home</h1>\n<p>Hello Agent Smith</p>"
    body("/inline").strip.should == "Hello <%= name %>"
  end

  it "with str as ext" do
    app.plugin :render, :ext => "str"
    body("/about").strip.should == "<h1>About Roda</h1>"
    body("/home").strip.should == "<title>Roda: Home</title>\n<h1>Home</h1>\n<p>Hello Agent Smith</p>"
    body("/inline").strip.should == "Hello Agent Smith"
  end

  it "custom default layout support" do
    app.plugin :render, :layout => "layout-alternative"
    body("/home").strip.should == "<title>Alternative Layout: Home</title>\n<h1>Home</h1>\n<p>Hello Agent Smith</p>"
  end

  it "using hash for :layout" do
    app.plugin :render, :layout => {:inline=> 'a<%= yield %>b'}
    body("/home").strip.should == "a<h1>Home</h1>\n<p>Hello Agent Smith</p>\nb"
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

  it "views without default layouts" do
    app(:bare) do
      plugin :render, :views=>"./spec/views", :layout=>false
      
      route do |r|
        view("home", :locals=>{:name=>"Agent Smith", :title=>"Home"})
      end
    end

    body.strip.should == "<h1>Home</h1>\n<p>Hello Agent Smith</p>"
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

  it ":layout=>true/false/string/hash/not-present respects plugin layout switch and template" do
    app(:bare) do
      plugin :render, :views=>"./spec/views", :layout_opts=>{:template=>'layout-yield', :locals=>{:title=>'a'}}
      
      route do |r|
        opts = {:content=>'bar'}
        opts[:layout] = true if r.path == '/'
        opts[:layout] = false if r.path == '/f'
        opts[:layout] = 'layout' if r.path == '/s'
        opts[:layout] = {:template=>'layout'} if r.path == '/h'
        view(opts)
      end
    end

    body.gsub("\n", '').should == "HeaderbarFooter"
    body('/a').gsub("\n", '').should == "HeaderbarFooter"
    body('/f').gsub("\n", '').should == "bar"
    body('/s').gsub("\n", '').should == "<title>Roda: a</title>bar"
    body('/h').gsub("\n", '').should == "<title>Roda: a</title>bar"

    app.plugin :render
    body.gsub("\n", '').should == "HeaderbarFooter"
    body('/a').gsub("\n", '').should == "HeaderbarFooter"
    body('/f').gsub("\n", '').should == "bar"
    body('/s').gsub("\n", '').should == "<title>Roda: a</title>bar"
    body('/h').gsub("\n", '').should == "<title>Roda: a</title>bar"

    app.plugin :render, :layout=>true
    body.gsub("\n", '').should == "HeaderbarFooter"
    body('/a').gsub("\n", '').should == "HeaderbarFooter"
    body('/f').gsub("\n", '').should == "bar"
    body('/s').gsub("\n", '').should == "<title>Roda: a</title>bar"
    body('/h').gsub("\n", '').should == "<title>Roda: a</title>bar"

    app.plugin :render, :layout=>'layout-alternative'
    body.gsub("\n", '').should == "<title>Alternative Layout: a</title>bar"
    body('/a').gsub("\n", '').should == "<title>Alternative Layout: a</title>bar"
    body('/f').gsub("\n", '').should == "bar"
    body('/s').gsub("\n", '').should == "<title>Roda: a</title>bar"
    body('/h').gsub("\n", '').should == "<title>Roda: a</title>bar"

    app.plugin :render, :layout=>nil
    body.gsub("\n", '').should == "<title>Alternative Layout: a</title>bar"
    body('/a').gsub("\n", '').should == "bar"
    body('/f').gsub("\n", '').should == "bar"
    body('/s').gsub("\n", '').should == "<title>Roda: a</title>bar"
    body('/h').gsub("\n", '').should == "<title>Roda: a</title>bar"

    app.plugin :render, :layout=>false
    body.gsub("\n", '').should == "<title>Alternative Layout: a</title>bar"
    body('/a').gsub("\n", '').should == "bar"
    body('/f').gsub("\n", '').should == "bar"
    body('/s').gsub("\n", '').should == "<title>Roda: a</title>bar"
    body('/h').gsub("\n", '').should == "<title>Roda: a</title>bar"
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

  it "template renders with :template opts" do
    app(:bare) do
      plugin :render, :views => "./spec/views"
      route do
        render(:template=>"about", :locals=>{:title => "About Roda"})
      end
    end
    body.strip.should == "<h1>About Roda</h1>"
  end

  it "template renders with :template_class opts" do
    app(:render) do
      @a = 1
      render(:inline=>'i#{@a}', :template_class=>::Tilt[:str])
    end
    body.should == "i1"
  end

  it "template cache respects :template_opts" do
    c = Class.new do 
      def initialize(path, _, opts)
        @path = path
        @opts = opts
      end
      def render(*)
        "#{@path}-#{@opts[:foo]}"
      end
    end

    app(:render) do |r|
      r.is "a" do
        render(:inline=>"i", :template_class=>c, :template_opts=>{:foo=>'a'})
      end
      r.is "b" do
        render(:inline=>"i", :template_class=>c, :template_opts=>{:foo=>'b'})
      end
    end

    body('/a').should == "i-a"
    body('/b').should == "i-b"
  end

  it "template cache respects :template_opts" do
    c = Class.new do 
      def initialize(path, _, opts)
        @path = path
        @opts = opts
      end
      def render(*)
        "#{@path}-#{@opts[:foo]}"
      end
    end

    app(:render) do |r|
      r.is "a" do
        render(:inline=>"i", :template_class=>c, :template_opts=>{:foo=>'a'})
      end
      r.is "b" do
        render(:inline=>"i", :template_class=>c, :template_opts=>{:foo=>'b'})
      end
    end

    body('/a').should == "i-a"
    body('/b').should == "i-b"
  end

  it "render_opts inheritance" do
    c = Class.new(Roda)
    c.plugin :render
    sc = Class.new(c)

    c.render_opts.should_not equal(sc.render_opts)
    c.render_opts[:cache].should_not equal(sc.render_opts[:cache])
  end

  it "render plugin call should not override options" do
    c = Class.new(Roda)
    c.plugin :render, :layout=>:foo
    c.plugin :render
    c.render_opts[:layout].should == :foo
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
