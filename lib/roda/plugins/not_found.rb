class Roda
  module RodaPlugins
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

          if result[0] == 404 && (v = result[2]).is_a?(Array) && v.empty?
            super{not_found}
          else
            result
          end
        end

        def not_found
        end
      end
    end
  end

  register_plugin(:not_found, RodaPlugins::NotFound)
end
