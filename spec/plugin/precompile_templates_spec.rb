require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

begin
  require 'tilt/erb'
rescue LoadError
  warn "tilt not installed, skipping precompiled_templates plugin test"  
else
describe "precompile_templates plugin" do 
  it "adds support for template precompilation" do
    app(:bare) do
      plugin :render, :views=>'spec/views'
      plugin :precompile_templates
      route do |r|
        @a = 1
        render('iv')
      end
    end

    app.render_opts[:cache][File.expand_path('spec/views/iv.erb')].should == nil
    app.precompile_templates 'spec/views/iv.erb'
    app.render_opts[:cache][File.expand_path('spec/views/iv.erb')].should_not == nil
    app.render_opts[:cache][File.expand_path('spec/views/iv.erb')].instance_variable_get(:@compiled_method)[[]].should_not == nil
    body.strip.should == '1'
  end

  it "adds support for template precompilation with :locals" do
    app(:bare) do
      plugin :render, :views=>'spec/views'
      plugin :precompile_templates
      route do |r|
        render('about', :locals=>{:title=>'1'})
      end
    end

    app.render_opts[:cache][File.expand_path('spec/views/about.erb')].should == nil
    app.precompile_templates 'spec/views/about.erb', :locals=>[:title]
    app.render_opts[:cache][File.expand_path('spec/views/about.erb')].should_not == nil
    app.render_opts[:cache][File.expand_path('spec/views/about.erb')].instance_variable_get(:@compiled_method)[[:title]].should_not == nil
    body.strip.should == '<h1>1</h1>'
  end

  it "adds support for template precompilation with sorting :locals" do
    app(:bare) do
      plugin :render, :views=>'spec/views'
      plugin :precompile_templates, :sort_locals=>true
      route do |r|
        render('home', :locals=>{:name => "Agent Smith", :title => "Home"})
      end
    end

    app.render_opts[:cache][File.expand_path('spec/views/home.erb')].should == nil
    app.precompile_templates 'spec/views/h*.erb', :locals=>[:title, :name]
    app.render_opts[:cache][File.expand_path('spec/views/home.erb')].should_not == nil
    app.render_opts[:cache][File.expand_path('spec/views/home.erb')].instance_variable_get(:@compiled_method)[[:name, :title]].should_not == nil
    body.strip.should == "<h1>Home</h1>\n<p>Hello Agent Smith</p>"
  end

  it "adds support for template precompilation with :inline" do
    app(:bare) do
      plugin :render, :views=>'spec/views'
      plugin :precompile_templates
      route do |r|
        render(:inline=>'a', :cache_key=>'a')
      end
    end

    app.render_opts[:cache]['a'].should == nil
    app.precompile_templates :inline=>'a', :cache_key=>'a'
    app.render_opts[:cache]['a'].should_not == nil
    app.render_opts[:cache]['a'].instance_variable_get(:@compiled_method)[[]].should_not == nil
    body.strip.should == "a"
  end
end
end
