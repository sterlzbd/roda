require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "integration" do 
  it "should setup middleware using use " do
    c = Class.new do
      def initialize(app, first, second, &block)
        @app, @first, @second, @block = app, first, second, block
      end

      def call(env)
        env["m.first"] = @first
        env["m.second"] = @second
        env["m.block"] = @block.call

        @app.call(env)
      end
    end

    app(:bare) do 
      use c, "First", "Second" do
        "Block"
      end

      route do |r|
        r.get "hello" do
          "D #{r.env['m.first']} #{r.env['m.second']} #{r.env['m.block']}"
        end
      end
    end

    body('/hello').should == 'D First Second Block'
  end
end
