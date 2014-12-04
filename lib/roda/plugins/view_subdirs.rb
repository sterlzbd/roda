class Roda
  module RodaPlugins
    # The view_subdirs plugin is designed for sites that have
    # outgrown a flat view directory and use subdirectories
    # for views.  It allows you to set the view directory to
    # use, and template names that do not contain a slash will
    # automatically use that view subdirectory.  Example:
    #
    #   plugin :render, :layout=>'./layout'
    #   plugin :view_subdirs
    #
    #   route do |r|
    #     r.on "users" do
    #       set_view_subdir 'users'
    #       
    #       r.get :id do
    #         view 'profile' # uses ./views/users/profile.erb
    #       end
    #
    #       r.get 'list' do
    #         view 'lists/users' # uses ./views/lists/users.erb
    #       end
    #     end
    #   end
    #
    # Note that when a view subdirectory is set, the layout will
    # also be looked up in the subdirectory unless it contains
    # a slash.  So if you want to use a view subdirectory for
    # templates but have a shared layout, you should make sure your
    # layout contains a slash, similar to the example above.
    module ViewSubdirs
      # Load the render plugin before this plugin, since this plugin
      # works by overriding a method in the render plugin.
      def self.load_dependencies(app)
        app.plugin :render
      end

      module InstanceMethods
        # Set the view subdirectory to use.  This can be set to nil
        # to not use a view subdirectory.
        def set_view_subdir(v)
          @_view_subdir = v
        end

        private

        # Override the template name to use the view subdirectory if the
        # there is a view subdirectory and the template name does not
        # contain a slash.
        def template_name(template)
          if (v = @_view_subdir) && (t = template.to_s) !~ /\//
            "#{v}/#{t}"
          else
            super
          end
        end
      end
    end

    register_plugin(:view_subdirs, ViewSubdirs)
  end
end
