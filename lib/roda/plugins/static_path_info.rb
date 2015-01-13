class Roda
  module RodaPlugins
    # The static_path_info plugin changes Roda's behavior so that the
    # SCRIPT_NAME/PATH_INFO environment settings are not modified
    # while the request is beind routed, improving performance.  If
    # you have any helpers that operate on PATH_INFO or SCRIPT_NAME,
    # their behavior will not change depending on where they are
    # called in the routing tree.
    #
    # This still updates SCRIPT_NAME/PATH_INFO before dispatching to
    # another rack app via +r.run+.
    module StaticPathInfo
      module RequestMethods
        PATH_INFO = "PATH_INFO".freeze
        SCRIPT_NAME = "SCRIPT_NAME".freeze

        # The current path to match requests against.  This is initialized
        # to PATH_INFO when the request is created.
        attr_reader :remaining_path

        # Set remaining_path when initializing.
        def initialize(*)
          super
          @remaining_path = @env[PATH_INFO]
        end

        # The already matched part of the path, including the original SCRIPT_NAME.
        def matched_path
          e = @env
          e[SCRIPT_NAME] + e[PATH_INFO].chomp(@remaining_path)
        end

        # Update SCRIPT_NAME/PATH_INFO based on the current remaining_path
        # before dispatching to another rack app, so the app still works as
        # a URL mapper.
        def run(_)
          e = @env
          path = @remaining_path
          begin
            script_name = e[SCRIPT_NAME]
            path_info = e[PATH_INFO]
            e[SCRIPT_NAME] += path_info.chomp(path)
            e[PATH_INFO] = path
            super
          ensure
            e[SCRIPT_NAME] = script_name
            e[PATH_INFO] = path_info
          end
        end

        private

        # Update remaining_path with the remaining characters
        def update_remaining_path(remaining)
          @remaining_path = remaining
        end

        # Yield to the block, restoring the remaining_path before
        # the method returns.
        def keep_remaining_path
          path = @remaining_path
          yield
        ensure
          @remaining_path = path
        end
      end
    end

    register_plugin(:static_path_info, StaticPathInfo)
  end
end
