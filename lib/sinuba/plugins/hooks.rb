class Sinuba
  module SinubaPlugins
    module Hooks
      def self.configure(mod)
        mod.instance_variable_set(:@before, nil)
        mod.instance_variable_set(:@after, nil)
      end

      module ClassMethods
        def after(&block)
          if block
            @after = if b = @after
              @after = proc do |res|
                instance_exec(res, &b)
                instance_exec(res, &block)
              end
            else
              block
            end
          end
          @after
        end

        def before(&block)
          if block
            @before = if b = @before
              @before = proc do
                instance_exec(&block)
                instance_exec(&b)
              end
            else
              block
            end
          end
          @before
        end

        def inherited(subclass)
          super
          subclass.instance_variable_set(:@before, @before)
          subclass.instance_variable_set(:@after, @after)
        end
      end
      module InstanceMethods
        private

        def _route(*, &block)
          if b = self.class.before
            instance_exec(&b)
          end

          res = super
        ensure
          if b = self.class.after
            instance_exec(res, &b)
          end
        end
      end
    end
  end

  register_plugin(:hooks, SinubaPlugins::Hooks)
end
