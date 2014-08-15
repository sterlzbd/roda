class Roda
  module RodaPlugins
    # The multi_route plugin allows for multiple named routes, which the
    # main route block can dispatch to by name at any point by calling +route+.
    # If the named route doesn't handle the request, execution will continue,
    # and if the named route does handle the request, the response returned by
    # the named route will be returned.
    #
    # In addition, this also adds the +r.multi_route+ method, which will assume
    # check if the first segment in the path matches a named route, and dispatch
    # to that named route.
    #
    # Example:
    #
    #   plugin :multi_route
    #
    #   route('foo') do |r|
    #     r.is 'bar' do
    #       '/foo/bar'
    #     end
    #   end
    #
    #   route('bar') do |r|
    #     r.is 'foo' do
    #       '/bar/foo'
    #     end
    #   end
    #
    #   route do |r|
    #     r.multi_route
    #
    #     # or
    #
    #     r.on "foo" do
    #       route 'foo'
    #     end
    #
    #     r.on "bar" do
    #       route 'bar'
    #     end
    #   end
    #
    # Note that in multi-threaded code, you should not attempt to add a
    # named route after accepting requests.
    #
    # If you want to use the +r.multi_route+ method, use string names for the
    # named routes.  Also, you can provide a block to +r.multi_route+ that is
    # called if the route matches but the named route did not handle the
    # request:
    #
    #   r.multi_route do
    #     "default body"
    #   end
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

        # An names for the currently stored named routes
        def named_routes
          @named_routes.keys
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

      module RequestClassMethods
        # A regexp matching any of the current named routes.
        def named_route_regexp
          @named_route_regexp ||= /(#{Regexp.union(roda_class.named_routes)})/
        end
      end

      module RequestMethods
        # Check if the first segment in the path matches any of the current
        # named routes.  If so, call that named route.  If not, do nothing.
        # If the named route does not handle the request, and a block
        # is given, yield to the block.
        def multi_route
          on self.class.named_route_regexp do |section|
            scope.route(section)
            yield if block_given?
          end
        end
      end
    end

    register_plugin(:multi_route, MultiRoute)
  end
end
