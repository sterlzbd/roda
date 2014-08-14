require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

begin
  require 'tilt/erb'
rescue LoadError
  warn "tilt not installed, skipping content_for plugin test"  
else
describe "content_for plugin" do
  before do
    app(:bare) do
      plugin :render
      render_opts[:views] = "./spec/views"
      plugin :content_for

      route do |r|
        r.root do
          view(:inline=>"<% content_for :foo do %>foo<% end %>bar", :layout=>{:inline=>'<%= yield %> <%= content_for(:foo) %>'})
        end
        r.get 'a' do
          view(:inline=>"bar", :layout=>{:inline=>'<%= content_for(:foo) %> <%= yield %>'})
        end
      end
    end
  end

  it "should be able to set content in template and get that content in the layout" do
    body.strip.should == "bar foo"
  end

  it "should work if content is not set by the template" do
    body('/a').strip.should == "bar"
  end
end
end
