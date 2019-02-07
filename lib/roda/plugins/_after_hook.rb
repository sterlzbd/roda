# frozen-string-literal: true

#
class Roda
  module RodaPlugins
    # Internal after hook module, not for external use.
    # Allows for plugins to configure the order in which
    # after processing is done by using _roda_after_*
    # private instance methods that are called in sorted order.
    # Loaded automatically by the base library if any _roda_after_*
    # methods are defined.
    module AfterHook # :nodoc:
      # Module for internal after hook support.
      module InstanceMethods
        # Run internal after hooks with the response
        def call
          res = super
        ensure
          _roda_after(res)
        end

        private

        # Empty roda_after method, so nothing breaks if the module is included.
        # This method will be overridden in most classes using this module.
        def _roda_after(res)
        end
      end
    end

    register_plugin(:_after_hook, AfterHook)
  end
end
