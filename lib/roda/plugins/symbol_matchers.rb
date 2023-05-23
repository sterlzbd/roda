# frozen-string-literal: true

#
class Roda
  module RodaPlugins
    # The symbol_matchers plugin allows you do define custom regexps to use
    # for specific symbols.  For example, if you have a route such as:
    #
    #   r.on :username do |username|
    #     # ...
    #   end
    #
    # By default this will match all nonempty segments.  However, if your usernames
    # must be 6-20 characters, and can only contain +a-z+ and +0-9+, you can do:
    #
    #   plugin :symbol_matchers
    #   symbol_matcher :username, /([a-z0-9]{6,20})/
    #
    # Then the route will only if the path is +/foobar123+, but not if it is
    # +/foo+, +/FooBar123+, or +/foobar_123+.
    #
    # By default, this plugin sets up the following symbol matchers:
    #
    # :d :: <tt>/(\d+)/</tt>, a decimal segment
    # :rest :: <tt>/(.*)/</tt>, all remaining characters, if any
    # :w :: <tt>/(\w+)/</tt>, a alphanumeric segment
    #
    # If the placeholder_string_matchers plugin is loaded, this feature also applies to
    # placeholders in strings, so the following:
    #
    #   r.on "users/:username" do |username|
    #     # ...
    #   end
    #
    # Would match +/users/foobar123+, but not +/users/foo+, +/users/FooBar123+,
    # or +/users/foobar_123+.
    #
    # If using this plugin with the params_capturing plugin, this plugin should
    # be loaded first.
    #
    # You can provide a block when calling +symbol_matcher+, and it will be called
    # for all matches to allow for type conversion.  The block must return an
    # array:
    #
    #   symbol_matcher(:date, /(\d\d\d\d)-(\d\d)-(\d\d)/) do |y, m, d|
    #     [Date.new(y.to_i, m.to_i, d.to_i)]
    #   end
    #
    #   route do |r|
    #     r.on :date do |date|
    #       # date is an instance of Date
    #     end
    #   end
    #
    # If you have a segment match the passed regexp, but decide during block
    # processing that you do not want to treat it as a match, you can have the
    # block return nil or false.  This is useful if you want to make sure you
    # are using valid data:
    #
    #   symbol_matcher(:date, /(\d\d\d\d)-(\d\d)-(\d\d)/) do |y, m, d|
    #     y = y.to_i
    #     m = m.to_i
    #     d = d.to_i
    #     [Date.new(y, m, d)] if Date.valid_date?(y, m, d)
    #   end
    #
    # However, if providing a block to the symbol_matchers plugin, the symbol may 
    # not work with the params_capturing plugin.
    module SymbolMatchers
      def self.load_dependencies(app)
        app.plugin :_symbol_regexp_matchers
      end

      def self.configure(app)
        app.symbol_matcher(:d, /(\d+)/)
        app.symbol_matcher(:w, /(\w+)/)
        app.symbol_matcher(:rest, /(.*)/)
      end

      module ClassMethods
        # Set the regexp to use for the given symbol, instead of the default.
        def symbol_matcher(s, re, &block)
          meth = :"match_symbol_#{s}"
          array = [re, block].freeze
          self::RodaRequest.send(:define_method, meth){array}
          self::RodaRequest.send(:private, meth)
        end
      end

      module RequestMethods
        private

        # Use regular expressions to the symbol-specific regular expression
        # if the symbol is registered.  Otherwise, call super for the default
        # behavior.
        def _match_symbol(s)
          meth = :"match_symbol_#{s}"
          if respond_to?(meth, true)
            # Allow calling private match methods
            re, block = send(meth)
            consume(self.class.cached_matcher(re){re}, &block)
          else
            super
          end
        end

        # Return the symbol-specific regular expression if one is registered.
        # Otherwise, call super for the default behavior.
        def _match_symbol_regexp(s)
          meth = :"match_symbol_#{s}"
          if respond_to?(meth, true)
            # Allow calling private match methods
            re, = send(meth)
            re
          else
            super
          end
        end
      end
    end

    register_plugin(:symbol_matchers, SymbolMatchers)
  end
end
