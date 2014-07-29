class Roda
  module RodaPlugins
    module MultiRoute
      def self.configure(mod)
        mod.instance_variable_set(:@named_routes, {})
      end

      module ClassMethods
        def route(name=nil, &block)
          if name
            @named_routes[name] = block
          else
            super(&block)
          end
        end

        def named_route(name)
          @named_routes[name]
        end

        def inherited(subclass)
          super
          subclass.instance_variable_set(:@named_routes, @named_routes.dup)
        end
      end

      module InstanceMethods
        def route(name)
          instance_exec(request, &self.class.named_route(name))
        end
      end
    end

    register_plugin(:multi_route, MultiRoute)
  end
end
