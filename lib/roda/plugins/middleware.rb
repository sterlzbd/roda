class Roda
  module RodaPlugins
    # The middleware plugin allows the Roda app to be used as
    # rack middleware.
    #
    # In the example below, requests to /mid will return Mid
    # by the Mid middleware, and requests to /app will not be
    # matched by the Mid middleware, so they will be forwarded
    # to App.
    #
    #   class Mid < Roda
    #     plugin :middleware
    #
    #     route do |r|
    #       r.is "mid" do
    #         "Mid"
    #       end
    #     end
    #   end
    #
    #   class App < Roda
    #     use Mid
    #
    #     route do |r|
    #       r.is "app" do
    #         "App"
    #       end
    #     end
    #   end
    #
    #   run App
    #
    # Note that once you use the middleware plugin, you can only use the
    # Roda app as middleware, and you will get errors if you attempt to
    # use it as a regular app.
    module Middleware
      # Forward instances are what is actually used as middleware.
      class Forwarder
        # Store the current middleware and the next middleware to call.
        def initialize(mid, app)
          @mid = mid.app
          @app = app
        end

        # When calling the middleware, first call the current middleware.
        # If this returns a result, return that result directly.  Otherwise,
        # pass handling of the request to the next middleware.
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
        # If an argument is given, this is a middleware app, so create a Forwarder.
        # Otherwise, this is a usual instance creation, so call super.
        def new(app=nil)
          if app
            Forwarder.new(self, app)
          else
            super()
          end
        end

        # Override the route block so that if no route matches, we throw so
        # that the next middleware is called.
        def route(&block)
          super do |r|
            instance_exec(r, &block)
            throw :next, true
          end
        end
      end
    end

    register_plugin(:middleware, Middleware)
  end
end
