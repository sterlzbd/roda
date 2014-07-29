class Roda
  module RodaPlugins
    # The default_headers plugin accept a hash of headers,
    # and overrides the default_headers method in the
    # response class to be a copy of the headers.
    #
    # Note that when using this module, you should not
    # attempt to mutate of the values set in the default
    # headers hash.
    #
    # Example:
    #
    #   plugin :default_headers, 'Content-Type'=>'text/csv'
    module DefaultHeaders
      def self.configure(app, headers)
        app.response_module do
          define_method(:default_headers) do
            headers.dup
          end
        end
      end
    end

    register_plugin(:default_headers, DefaultHeaders)
  end
end
