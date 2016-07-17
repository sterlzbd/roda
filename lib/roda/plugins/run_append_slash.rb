# frozen-string-literal: true

#
class Roda
  module RodaPlugins
    # The run_append_slash plugin automatically adds a trailing slash
    # redirect where rack applications are mounted using <tt>run</tt> when a
    # trailing slash is missing.
    module RunAppendSlash
      OPTS = {}.freeze
      # Set plugin specific options.  Options:
      # :use_redirects :: Whether to issue 302 redirects when appending the
      # trailing slash.
      def self.configure(app, opts=OPTS)
        app.opts[:append_slash_redirect] = !!opts[:use_redirects]
      end
      module RequestMethods
        # Calls the given rack app. If the path matches the root of the app but
        # does not contain a trailing slash, a trailing slash is appended to the
        # path internally. A redirect is issued when configured with
        # <tt>use_redirects: true</tt>.
        def run(app)
          if remaining_path.empty?
            if scope.opts[:append_slash_redirect]
              redirect path + '/'
            else
              @remaining_path = @remaining_path + '/'
            end
          end
          super
        end
      end
    end

    register_plugin(:run_append_slash, RunAppendSlash)
  end
end
