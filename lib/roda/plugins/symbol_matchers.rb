class Roda
  module RodaPlugins
    # The symbol_matchers plugin allows you do define custom regexps to use
    # for specific symbols.  For example, if you have a route such as:
    #
    #   r.on :username do
    #     # ...
    #   end
    #
    # By default this will match all segments.  However, if your usernames
    # must be 6-20 characters, and can only contain +a-z+ and +0-9+, you can do:
    #
    #   plugin :symbol_matchers
    #   symbol_matcher :username, /([a-z0-9]{6,20})/
    #
    # Then the route will only if the path is +/foobar123+, but not if it is
    # +/foo+, +/FooBar123+, or +/foobar_123+.
    #
    # Note that this feature does not apply to just symbols, but also to
    # embedded colons in strings, so the following:
    #
    #   r.on "users/:username" do
    #     # ...
    #   end
    #
    # Would match +/users/foobar123+, but not +/users/foo+, +/users/FooBar123+,
    # or +/users/foobar_123+.
    #
    # By default, this plugin sets up two symbol matchers:
    #
    # :d :: <tt>/\d+/</tt>
    # :w :: <tt>/\w+/</tt>
    module SymbolMatchers
      def self.configure(app)
        app.symbol_matcher(:d, /(\d+)/)
        app.symbol_matcher(:w, /(\w+)/)
      end

      module ClassMethods
        # Set the regexp to use for the given symbol, instead of the default.
        def symbol_matcher(s, re)
          request_module{define_method(:"match_symbol_#{s}"){re}}
        end
      end

      module RequestMethods
        # Allow for symbol specific regexps, by using match_symbol_#{s} if
        # defined.  If not defined, calls super for the default behavior.
        def _match_symbol_regexp(s)
          meth = :"match_symbol_#{s}"
          if respond_to?(meth)
            send(meth)
          else
            super
          end
        end
      end
    end

    register_plugin(:symbol_matchers, SymbolMatchers)
  end
end
