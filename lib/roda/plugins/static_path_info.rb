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
        attr_reader :path_to_match

        # Set path_to_match when initializing.
        def initialize(*)
          super
          @path_to_match = @env[PATH_INFO]
        end

        # The already matched part of the path, including the original SCRIPT_NAME.
        def matched_path
          e = @env
          e[SCRIPT_NAME] + e[PATH_INFO].chomp(@path_to_match)
        end

        # Update SCRIPT_NAME/PATH_INFO based on the current path_to_match
        # before dispatching to another rack app, so the app still works as
        # a URL mapper.
        def run(_)
          e = @env
          path = @path_to_match
          e[SCRIPT_NAME] += e[PATH_INFO].chomp(path)
          e[PATH_INFO] = path
          super
        end

        private

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
