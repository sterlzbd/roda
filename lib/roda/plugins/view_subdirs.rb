# View options is a superset of the view_subdirs plugin,
# which no longer exists.  For backwards compatibility,
# make attempts to load the view_subdirs plugin load the
# view_options plugin instead.
require 'roda/plugins/view_options'
Roda::RodaPlugins.warn "The view_subdirs plugin is a deprecated alias for the view_options plugin that will be removed in Roda 3.  Use the view_options plugin instead."
Roda::RodaPlugins.register_plugin(:view_subdirs, Roda::RodaPlugins::ViewOptions)
