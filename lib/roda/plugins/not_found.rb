class Roda
  module RodaPlugins
    # The not_found plugin adds a +not_found+ class method which sets
    # a block that is called whenever a 404 response with an empty body
    # would be returned.  The usual use case for this is the desire for
    # nice error pages if the page is not found.
    #
    # You can provide the block with the plugin call:
    #
    #   plugin :not_found do
    #     "Where did it go?"
    #   end
    #   
    # Or later via a separate call to +not_found+:
    #
    #   plugin :not_found
    #
    #   not_found do
    #     "Where did it go?"
    #   end
    #
    # Before not_found is called, any existing headers on the response
    # will be cleared.  So if you want to be sure the headers are set
    # even in a not_found block, you need to reset them in the
    # not_found block.
    #
    # The not_found plugin also handles heartbeat/status requests.  While there
    # are rack middleware that handle heartbeat/status requests, in general they
    # slow down every request because they check the path of the request before
    # calling the app. By tying the heartbeat requests to the not_found handling,
    # there is no negative performance affect for heartbeat/status handling.
    # To enable heartbeat/status request handling, pass a :heartbeat option
    # with the path to handle for heartbeats:
    #
    #   plugin :not_found, :heartbeat=>'/heartbeat'
    #
    # Any requests for /heartbeat will get a 200 response with text/plain Content-Type
    # and a body of "OK".
    module NotFound
      OPTS = {}.freeze
      PATH_INFO = 'PATH_INFO'.freeze
      HEARTBEAT_RESPONSE = [200, {'Content-Type'=>'text/plain'}.freeze, ['OK'].freeze].freeze

      # If a block is given, install the block as the not_found handler.
      def self.configure(app, opts=OPTS, &block)
        app.opts[:not_found_heartbeat] = opts.fetch(:heartbeat, app.opts[:not_found_heartbeat])
        if block
          app.not_found(&block)
        end
      end

      module ClassMethods
        # Install the given block as the not_found handler.
        def not_found(&block)
          define_method(:not_found, &block)
          private :not_found
        end
      end

      module InstanceMethods
        # If routing returns a 404 response with an empty body, call
        # the not_found handler.
        def call
          result = super

          if result[0] == 404 && (v = result[2]).is_a?(Array) && v.empty?
            @_response.headers.clear
            if env[PATH_INFO] == opts[:not_found_heartbeat]
              HEARTBEAT_RESPONSE
            else
              super{not_found}
            end
          else
            result
          end
        end

        private

        # Use an empty not_found_handler by default, so that loading
        # the plugin without defining a not_found handler doesn't
        # break things.
        def not_found
        end
      end
    end

    register_plugin(:not_found, NotFound)
  end
end
