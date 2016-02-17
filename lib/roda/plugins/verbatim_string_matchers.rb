# frozen-string-literal: true

#
class Roda
  module RodaPlugins
    # The verbatim_string_matchers plugin makes the string matchers
    # only match verbatim strings.  So colons in strings are matched
    # literally, they do not serve as placeholders.  This can be
    # significantly faster as simple string operations can be used
    # instead of more time consuming regular expression searches.
    #
    # In addition to changing the standard string matchers to
    # use verbatim strings, this also adds two optimized matcher methods,
    # +r.on_prefix+ and +r.is_exactly+.  +r.on_prefix+ is an optimized version of
    # +r.on+ that only accepts a single string, and +r.is_exactly+ is an
    # optimized version of +r.is+ that only accepts a single string.
    #
    #   plugin :verbatim_string_matchers
    #
    #   route do |r|
    #     r.on "foo" do
    #       # matches /foo and paths starting with /foo/
    #     end
    #
    #     r.is "bar/:baz" do
    #       # matches literal /bar/:baz, not /bar/something_else
    #     end
    #
    #     r.on_prefix "x" do
    #       # matches /x and paths starting with /x/
    #       r.is_exactly "y" do
    #         # matches /x/y
    #       end
    #     end
    #   end
    #
    # Note that it's fairly easy to convert an existing routing tree
    # that uses strings with embedded colons.  You can convert this
    # style:
    #
    #   r.on "foo/:bar/:baz" do |bar, baz|
    #   end
    #
    # to:
    #
    #   r.on "foo", :bar, :baz do |bar, baz|
    #   end
    #
    # If you are using suffix matching via strings with embedded
    # colons, you would have to switch to regexps.  For example, you
    # would need to convert:
    # 
    #   r.on "foo/:bar/x-:baz" do |bar, baz|
    #   end
    #
    # to:
    #
    #   r.on "foo", :bar, /x-([^\/]+)/ do |bar, baz|
    #   end
    #
    # This plugin is not compatible with the params_capturing plugin
    # if strings with embedded colons are used as matchers.
    module VerbatimStringMatchers
      module RequestMethods
        SLASH = '/'.freeze
        EMPTY = ''.freeze

        # Optimized version of +on+ that only supports a single string.
        def on_prefix(s)
          always{yield} if _match_string(s)
        end

        # Optimized version of +is+ that only supports a single string.
        def is_exactly(s)
          rp = @remaining_path
          case _match_string(s)
          when EMPTY
            always{yield}
          when nil
            nil
          else
            @remaining_path = rp
          end
        end

        private

        # Only match the string to the remaining path if the remaining
        # path starts with a slash and then the string, and there is
        # nothing after the string or the remaining path after the
        # string starts with a slash.  In other words, this only matches
        # exact path segment(s) containing the string.
        def _match_string(str)
         rp = @remaining_path
         if rp.start_with?("/#{str}")
            last = str.length + 1
            case rp[last]
            when SLASH
              @remaining_path = rp[last, rp.length]
            when nil
              @remaining_path = EMPTY
            end
          end
        end
      end
    end

    register_plugin(:verbatim_string_matchers, VerbatimStringMatchers)
  end
end
