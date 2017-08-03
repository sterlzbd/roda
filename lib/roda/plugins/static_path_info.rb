class Roda
  module RodaPlugins
    warn 'The static_path_info plugin is deprecated and will be removed in Roda 3.  It has been a no-op since Roda 2, and can just be removed from the application.'

    module StaticPathInfo
    end

    # For backwards compatibilty, don't raise an error
    # if trying to load the plugin
    register_plugin(:static_path_info, StaticPathInfo)
  end
end
