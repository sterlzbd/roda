class Sinuba
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
      def call(env)
        super
      rescue => e
        catch(:halt) do
          request.on do
            handle_error(e)
          end
        end
      end

      private

      def handle_error
      end
    end
  end

  register_plugin(:error_handler, ErrorHandler)
end
