require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

begin
  require 'tilt/erb'
  require 'tilt/haml'
rescue LoadError
  warn "tilt, erb, or haml not installed, skipping content_for plugin test"
else
describe "content_for plugin with erb" do
  before do
    app(:bare) do
      plugin :render, :views => './spec/views'
      plugin :content_for

      route do |r|
        r.root do
          view(:inline => "<% content_for :foo do %>foo<% end %>bar", :layout => { :inline => '<%= yield %> <%= content_for(:foo) %>' })
        end
        r.get 'a' do
          view(:inline => "bar", :layout => { :inline => '<%= content_for(:foo) %> <%= yield %>' })
        end
      end
    end
  end

  it "should be able to set content in template and get that content in the layout" do
    body.strip.must_equal "bar foo"
  end

  it "should work if content is not set by the template" do
    body('/a').strip.must_equal "bar"
  end
end

describe "content_for plugin with haml" do
  before do
    app(:bare) do
      plugin :render, :engine => 'haml'
      plugin :content_for

      route do |r|
        r.root do
          view(:inline => "- content_for :foo do\n  - capture_haml do\n    foo\nbar", :layout => { :inline => "= yield\n=content_for :foo" })
        end
      end
    end
  end

  it "should work with alternate rendering engines" do
    body.strip.must_equal "bar\nfoo"
  end
end

describe "content_for plugin with mixed template engines" do
  before do
    app(:bare) do
      plugin :render, :layout_opts=>{:engine => 'haml', :inline => "= yield\n=content_for :foo" }
      plugin :content_for

      route do |r|
        r.root do
          view(:inline => "<% content_for :foo do %>foo<% end %>bar")
        end
      end
    end
  end

  it "should work with alternate rendering engines" do
    body.strip.must_equal "bar\nfoo"
  end
end

describe "content_for plugin when overriding :engine" do
  before do
    app(:bare) do
      plugin :render, :engine => 'haml', :layout_opts=>{:inline => "= yield\n=content_for :foo" }
      plugin :content_for

      route do |r|
        r.root do
          view(:inline => "<% content_for :foo do %>foo<% end %>bar", :engine=>:erb)
        end
      end
    end
  end

  it "should work with alternate rendering engines" do
    body.strip.must_equal "bar\nfoo"
  end
end
end
