require_relative "../spec_helper"

begin
  require 'tilt/erb'
rescue LoadError
  warn "tilt not installed, skipping capture_erb plugin test"
else
describe "capture_erb plugin" do
  before do
    app(:bare) do
      plugin :render, :views => './spec/views'
      plugin :capture_erb
      plugin :inject_erb

      route do |r|
        r.root do
          render(:inline => "<% value = capture_erb do %>foo<% end %>bar<%= value %>")
        end
        r.get 'rescue' do
          render(:inline => "<% value = capture_erb do %>foo<% raise %><% end rescue (value = 'baz') %>bar<%= value %>")
        end
        r.get 'inject' do
          render(:inline => "<% some_method do %>foo<% end %>")
        end
        r.get 'outside' do
          capture_erb{1}
        end
      end

      def some_method(&block)
        inject_erb "bar"
        inject_erb capture_erb(&block).upcase
        inject_erb "baz"
      end
    end
  end

  it "should capture erb output" do
    body.strip.must_equal "barfoo"
  end

  it "should handle exceptions in captured blocks" do
    body('/rescue').strip.must_equal "barbaz"
  end

  it "should work with the inject_erb plugin" do
    body('/inject').strip.must_equal "barFOObaz"
  end

  it "should return result of block converted to string when used outside template" do
    body('/outside').must_equal "1"
  end
end
end
