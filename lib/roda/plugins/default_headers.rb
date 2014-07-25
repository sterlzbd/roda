class Roda
  module RodaPlugins
    module DefaultHeaders
      def self.configure(mod, headers)
        mod.response_module do
          define_method(:default_headers) do
            headers.dup
          end
        end
      end
    end
  end

  register_plugin(:default_headers, RodaPlugins::DefaultHeaders)
end
