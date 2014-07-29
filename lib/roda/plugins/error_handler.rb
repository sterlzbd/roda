class Roda
  module RodaPlugins
    # The error_handler plugin adds an error handler to the routing,
    # so that if routing the request raises an error, a nice error
    # message page can be returned to the user.
    # 
    # You can provide the error handler as a block to the plugin:
    #
    #   plugin :error_handler do |e|
    #     "Oh No!"
    #   end
    #
    # Or later via the +error+ class method:
    #
    #   plugin :error_handler
    #
    #   error do |e|
    #     "Oh No!"
    #   end
    #
    # In both cases, the exception instance is passed into the block,
    # and the block can return the request body via a string.
    #
    # If an exception is raised, the response status will be set to 500
    # before executing the error handler.  The error handler can change
    # the response status if necessary.
    module ErrorHandler
      # If a block is given, automatically call the +error+ method on
      # the Roda class with it.
      def self.configure(app, &block)
        if block
          app.error(&block)
        end
      end

      module ClassMethods
        # Install the given block as the error handler, so that if routing
        # the request raises an exception, the block will be called with
        # the exception in the scope of the Roda instance.
        def error(&block)
          define_method(:handle_error, &block)
          private :handle_error
        end
      end

      module InstanceMethods
        private

        # If an error occurs, set the response status to 500 and call
        # the error handler.
        def _route
          super
        rescue => e
          response.status = 500
          super{handle_error(e)}
        end

        # By default, have the error handler reraise the error, so using
        # the plugin without installing an error handler doesn't change
        # behavior.
        def handle_error(e)
          raise e
        end
      end
    end

    register_plugin(:error_handler, ErrorHandler)
  end
end
