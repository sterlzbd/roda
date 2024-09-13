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
    # :w :: <tt>/(\w+)/</tt>, an alphanumeric segment
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
    # for all matches to allow for type conversion:
    #
    #   symbol_matcher(:date, /(\d\d\d\d)-(\d\d)-(\d\d)/) do |y, m, d|
    #     Date.new(y.to_i, m.to_i, d.to_i)
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
    #     Date.new(y, m, d) if Date.valid_date?(y, m, d)
    #   end
    #
    # You can have the block return an array to yield multiple captures.
    #
    # The second argument to symbol_matcher can be a symbol already registered
    # as a symbol matcher. This can DRY up code that wants a conversion
    # performed by an existing class matcher or to use the same regexp:
    #
    #   symbol_matcher :employee_id, :d do |id|
    #     id.to_i
    #   end
    #   symbol_matcher :employee, :employee_id do |id|
    #     Employee[id]
    #   end
    #
    # With the above example, the :d matcher matches only decimal strings, but
    # yields them as string.  The registered :employee_id matcher converts the
    # decimal string to an integer.  The registered :employee matcher builds
    # on that and uses the integer to lookup the related employee.  If there is
    # no employee with that id, then the :employee matcher will not match.
    #
    # If using the class_matchers plugin, you can provide a recognized class
    # matcher as the second argument to symbol_matcher, and it will work in
    # a similar manner:
    #
    #   symbol_matcher :employee, Integer do |id|
    #     Employee[id]
    #   end
    #
    # Blocks passed to the symbol matchers plugin are evaluated in route
    # block context.
    #
    # If providing a block to the symbol_matchers plugin, the symbol may 
    # not work with the params_capturing plugin. Note that the use of
    # symbol matchers inside strings when using the placeholder_string_matchers
    # plugin only uses the regexp, it does not respect the conversion blocks
    # registered with the symbols.
    module SymbolMatchers
      def self.load_dependencies(app)
        app.plugin :_symbol_regexp_matchers
      end

      def self.configure(app)
        app.opts[:symbol_matchers] ||= {}
        app.symbol_matcher(:d, /(\d+)/)
        app.symbol_matcher(:w, /(\w+)/)
        app.symbol_matcher(:rest, /(.*)/)
      end

      module ClassMethods
        # Set the matcher and block to use for the given class.
        # The matcher can be a regexp, registered symbol matcher, or registered class
        # matcher (if using the class_matchers plugin).
        #
        # If providing a regexp, the block given will be called with all regexp captures.
        # If providing a registered symbol or class, the block will be called with the
        # captures returned by the block for the registered symbol or class, or the regexp
        # captures if no block was registered with the symbol or class. In either case,
        # if a block is given, it should return an array with the captures to yield to
        # the match block.
        def symbol_matcher(s, matcher, &block)
          meth = :"match_symbol_#{s}"

          case matcher
          when Regexp
            regexp = matcher
            consume_regexp = self::RodaRequest.send(:consume_pattern, regexp)
          when Symbol
            regexp, consume_regexp, matcher_block = opts[:symbol_matchers][matcher]

            unless regexp
              raise RodaError, "unregistered symbol matcher given to symbol_matcher: #{matcher.inspect}"
            end

            block = merge_symbol_matcher_blocks(s, block, matcher_block)
          when Class
            unless opts[:class_matchers]
              raise RodaError, "cannot provide Class matcher to symbol_matcher unless using class_matchers plugin: #{matcher.inspect}"
            end

            regexp, consume_regexp, matcher_block = opts[:class_matchers][matcher]
            unless regexp
              raise RodaError, "unregistered class matcher given to symbol_matcher: #{matcher.inspect}"
            end
            block = merge_symbol_matcher_blocks(s, block, matcher_block)
          else
            raise RodaError, "unsupported matcher given to symbol_matcher: #{matcher.inspect}"
          end

          if block.is_a?(Symbol)
            convert_meth = block
          elsif block
            convert_meth = :"_convert_symbol_#{s}"
            define_method(convert_meth, &block)
            private convert_meth
          end

          array = opts[:symbol_matchers][s] = [regexp, consume_regexp, convert_meth].freeze

          self::RodaRequest.class_eval do
            define_method(meth){array}
            private meth
          end

          nil
        end

        # Freeze the class_matchers hash when freezing the app.
        def freeze
          opts[:symbol_matchers].freeze
          super
        end

        private

        # If both block and matcher_block are given, return a
        # proc that calls matcher block first, and only calls
        # block with the return values of matcher_block if
        # the matcher_block returns an array.
        # Otherwise, return matcher_block or block.
        def merge_symbol_matcher_blocks(sym, block, matcher_meth)
          if matcher_meth
            if block
              convert_meth = :"_convert_merge_symbol_#{sym}"
              define_method(convert_meth, &block)
              private convert_meth

              proc do |*a|
                if captures = send(matcher_meth, *a)
                  send(convert_meth, *captures)
                end
              end
            else
              matcher_meth
            end
          else
            block
          end
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
            _, re, convert_meth = send(meth)
            consume(re, convert_meth)
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
