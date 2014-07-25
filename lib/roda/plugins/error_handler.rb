class Roda
  module RodaPlugins
    module ErrorHandler
      def self.configure(app, &block)
        if block
          app.error(&block)
        end
      end

      module ClassMethods
        def error(&block)
          define_method(:handle_error, &block)
          private :handle_error
        end
      end

      module InstanceMethods
        private

        def _route
          super
        rescue => e
          catch(:halt) do
            request.on do
              handle_error(e)
            end
          end
        end

        def handle_error
        end
      end
    end
  end

  register_plugin(:error_handler, RodaPlugins::ErrorHandler)
end
