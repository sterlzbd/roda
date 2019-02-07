# frozen-string-literal: true

#
class Roda
  module RodaPlugins
    # Deprecated plugin, only exists for backwards compatibility.
    # Features are now part of base library.
    module BeforeHook # :nodoc:
    end

    register_plugin(:_before_hook, BeforeHook)
  end
end
