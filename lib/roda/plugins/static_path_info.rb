class Roda
  module RodaPlugins
    # The static_path_info plugin changes Roda's behavior so that the
    # SCRIPT_NAME/PATH_INFO environment settings are not modified
    # while the request is beind routed.  This is faster, but it means
    # that the Roda app will not be usable as a URL mapper anymore.  If
    # you aren't calling RodaRequest#run to send the request to another
    # rack application, you can probably get a performance improvement
    # by using this plugin.  Additionally, if you have any helpers that
    # operate on PATH_INFO or SCRIPT_NAME, their behavior will not change
    # depending on where they are called in the routing tree.
    module StaticPathInfo
      module RequestMethods
        PATH_INFO = "PATH_INFO".freeze

        # Set path_to_match when initializing.
        def initialize(*)
          super
          @path_to_match = @env[PATH_INFO]
        end

        private

        # The current path to match requests against.  This is initialized
        # to PATH_INFO when the request is created.
        attr_reader :path_to_match

        # Update path_to_match with the remaining characters
        def update_path_to_match(remaining)
          @path_to_match = remaining
        end

        # Yield to the block, restoring the path_to_match before
        # the method returns.
        def keep_path_to_match
          path = @path_to_match
          yield
        ensure
          @path_to_match = path
        end
      end
    end

    register_plugin(:static_path_info, StaticPathInfo)
  end
end
