require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "integration" do 
  before do
    @c = Class.new do
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

  end

  it "should setup middleware using use " do
    c = @c
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

  it "should inherit middleware in subclass " do
    c = @c
    @app = Class.new(app(:bare){use(c, '1', '2'){"3"}})
    @app.route do  |r|
      r.get "hello" do
        "D #{r.env['m.first']} #{r.env['m.second']} #{r.env['m.block']}"
      end
    end

    body('/hello').should == 'D 1 2 3'
  end

  it "should not have future middleware additions to parent class affect subclass " do
    c = @c
    a = app
    @app = Class.new(a)
    @app.route do  |r|
      r.get "hello" do
        "D #{r.env['m.first']} #{r.env['m.second']} #{r.env['m.block']}"
      end
    end
    a.use(c, '1', '2'){"3"}

    body('/hello').should == 'D   '
  end
end
