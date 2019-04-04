# frozen-string-literal: true

#
class Roda
  module RodaPlugins
    module DelayBuild
    end

    # RODA4: Remove plugin
    # Only available for backwards compatibility, no longer needed
    register_plugin(:delay_build, DelayBuild)
  end
end
