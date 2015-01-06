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
    module NotFound
      # If a block is given, install the block as the not_found handler.
      def self.configure(app, &block)
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
        private

        # If routing returns a 404 response with an empty body, call
        # the not_found handler.
        def _route
          result = super

          if result[0] == 404 && (v = result[2]).is_a?(Array) && v.empty?
            @_response.headers.clear
            super{not_found}
          else
            result
          end
        end

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
