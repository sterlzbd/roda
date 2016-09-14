# frozen-string-literal: true

#
class Roda
  module RodaPlugins
    module H
    end

    # For backwards compatibilty, don't raise an error
    # if trying to load the plugin
    register_plugin(:h, H)
  end
end
