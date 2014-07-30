class Roda
  module RodaPlugins
    # The multi_route plugin allows for multiple named routes, which the
    # main route block can dispatch to by name at any point.  If the named
    # route doesn't handle the request, execution will continue, and if the
    # named route does handle the request, the response by the named route
    # will be returned.
    #
    # Example:
    #
    #   plugin :multi_route
    #
    #   route(:foo) do |r|
    #     r.is 'bar' do
    #       '/foo/bar'
    #     end
    #   end
    #
    #   route(:bar) do |r|
    #     r.is 'foo' do
    #       '/bar/foo'
    #     end
    #   end
    #
    #   route do |r|
    #     r.on "foo" do
    #       route :foo
    #     end
    #
    #     r.on "bar" do
    #       route :bar
    #     end
    #   end
    #
    # Note that in multi-threaded code, you should not attempt to add a
    # named route after accepting requests.
    module MultiRoute
      # Initialize storage for the named routes.
      def self.configure(app)
        app.instance_exec{@named_routes ||= {}}
      end

      module ClassMethods
        # Copy the named routes into the subclass when inheriting.
        def inherited(subclass)
          super
          subclass.instance_variable_set(:@named_routes, @named_routes.dup)
        end

        # Return the named route with the given name.
        def named_route(name)
          @named_routes[name]
        end

        # If the given route has a named, treat it as a named route and
        # store the route block.  Otherwise, this is the main route, so
        # call super.
        def route(name=nil, &block)
          if name
            @named_routes[name] = block
          else
            super(&block)
          end
        end
      end

      module InstanceMethods
        # Dispatch to the named route with the given name.
        def route(name)
          instance_exec(request, &self.class.named_route(name))
        end
      end
    end

    register_plugin(:multi_route, MultiRoute)
  end
end
