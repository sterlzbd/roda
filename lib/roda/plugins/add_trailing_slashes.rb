# frozen-string-literal: true

#
class Roda
  module RodaPlugins
    # The add_trailing_slashes plugin automatically adds a trailing slash
    # redirect where rack applications are mounted using <tt>run</tt> when a
    # trailing slash is missing.
    module AddTrailingSlashes
      module RequestMethods
        # Calls the given rack app. If the path matches the root of the app but
        # does not contain a trailing slash, a redirect appending the missing
        # trailing slash is issued.
        def run(app)
          is do
            redirect path + "/" if path[-1] != "/"
          end
          super
        end
      end
    end

    register_plugin(:add_trailing_slashes, AddTrailingSlashes)
  end
end
