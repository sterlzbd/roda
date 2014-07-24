require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "plugins" do
  it "should be able to override class, instance, response, and request methods, and execute configure method" do
    c = Module.new do
      self::ClassMethods = Module.new do
        def fix(str)
          opts[:prefix] + str.strip
        end
      end
      self::InstanceMethods = Module.new do
        def fix(str)
          super("a" + str)
        end
      end
      self::RequestMethods = Module.new do
        def hello(&block)
          on 'hello', &block
        end
      end
      self::ResponseMethods = Module.new do
        def foobar
          "Default   "
        end
      end

      def self.load_dependencies(mod, prefix)
        mod.send(:include, Module.new do
          def fix(str)
            self.class.fix(str)
          end
        end)
      end

      def self.configure(mod, prefix)
        mod.opts[:prefix] = prefix
      end
    end

    app(:bare) do
      plugin c, "Foo "

      route do |r|
        r.hello do
          fix(response.foobar)
        end
      end
    end

    body('/hello').should == 'Foo aDefault'
  end
end
