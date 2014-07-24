class Sinuba
  module SinubaPlugins
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
        private

        def _route
          result = super

          if result[0] == 404 && result[2].is_a?(Array) && result[2].empty?
            catch(:halt) do
              request.on do
                not_found
              end
            end
          end

          result
        end

        def not_found
        end
      end
    end
  end

  register_plugin(:not_found, SinubaPlugins::NotFound)
end
