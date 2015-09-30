class Roda
  module RodaPlugins
    # The default_status plugin accepts a block which should
    # return a response status integer. This integer will be used as
    # the default response status (usually 200) if the body has been
    # written to, and you have not explicitly set a response status.
    #
    # Example:
    #
    #   # Use 201 default response status for all requests
    #   plugin :default_status do
    #     201
    #   end
    #
    module DefaultStatus
      def self.configure(app, &block)
        app.opts[:default_status] = block
      end

      module ResponseMethods
        # Get the default response status from the related Roda class.
        def default_status
          instance_exec(&roda_class.opts[:default_status])
        end
      end
    end

    register_plugin(:default_status, DefaultStatus)
  end
end
