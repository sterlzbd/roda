class Sinuba
  module NotFound
    def self.configure(app, &block)
      if block
        app.not_found(&block)
      end
    end

    module ClassMethods
      def not_found(&block)
        define_method(:not_found, &block)
        private :not_found
      end
    end

    module InstanceMethods
      def call(env)
        result = super

        if result[0] == 404 && result[2].is_a?(Array) && result[2].empty?
          catch(:halt) do
            request.on do
              not_found
            end

            response.finish
          end
        end

        result
      end

      private

      def not_found
      end
    end
  end

  register_plugin(:not_found, NotFound)
end
