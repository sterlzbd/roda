class Roda
  module RodaPlugins
    module Middleware
      class Forwarder
        def initialize(mid, app)
          @mid = mid.app
          @app = app
        end

        def call(env)
          res = nil

          call_next = catch(:next) do
            res = @mid.call(env)
            false
          end

          if call_next
            @app.call(env)
          else
            res
          end
        end
      end

      module ClassMethods
        def new(app=nil)
          if app
            Forwarder.new(self, app)
          else
            super()
          end
        end

        def route(&block)
          super do |r|
            instance_exec(r, &block)
            throw :next, true
          end
        end
      end
    end
  end

  register_plugin(:middleware, RodaPlugins::Middleware)
end
