# frozen-string-literal: true

#
class Roda
  module RodaPlugins
    # The class_matchers plugin allows you do define custom regexps and
    # conversion procs to use for specific classes.  For example, if you
    # have multiple routes similar to:
    #
    #   r.on /(\d\d\d\d)-(\d\d)-(\d\d)/ do |y, m, d|
    #     date = Date.new(y.to_i, m.to_i, d.to_i)
    #     # ...
    #   end
    #
    # You can register a Date class matcher for that regexp:
    #
    #   class_matcher(Date, /(\d\d\d\d)-(\d\d)-(\d\d)/) do |y, m, d|
    #     Date.new(y.to_i, m.to_i, d.to_i)
    #   end
    #
    # And then use the Date class as a matcher, and it will yield a Date object:
    #
    #   r.on Date do |date|
    #     # ...
    #   end
    #
    # This is useful to DRY up code if you are using the same type of pattern and
    # type conversion in multiple places in your application. You can have the
    # block return an array to yield multiple captures.
    #
    # If you have a segment match the passed regexp, but decide during block
    # processing that you do not want to treat it as a match, you can have the
    # block return nil or false.  This is useful if you want to make sure you
    # are using valid data:
    #
    #   class_matcher(Date, /(\d\d\d\d)-(\d\d)-(\d\d)/) do |y, m, d|
    #     y = y.to_i
    #     m = m.to_i
    #     d = d.to_i
    #     Date.new(y, m, d) if Date.valid_date?(y, m, d)
    #   end
    #
    # The second argument to class_matcher can be a class already registered
    # as a class matcher. This can DRY up code that wants a conversion
    # performed by an existing class matcher:
    #
    #   class_matcher Employee, Integer do |id|
    #     Employee[id]
    #   end
    #
    # With the above example, the Integer matcher performs the conversion to
    # integer, so +id+ is yielded as an integer.  The block then looks up the
    # employee with that id.  If there is no employee with that id, then
    # the Employee matcher will not match.
    #
    # If using the symbol_matchers plugin, you can provide a recognized symbol
    # matcher as the second argument to class_matcher, and it will work in
    # a similar manner:
    #
    #   symbol_matcher(:employee_id, /E-(\d{6})/) do |employee_id|
    #     employee_id.to_i
    #   end
    #   class_matcher Employee, :employee_id do |id|
    #     Employee[id]
    #   end
    #
    # Blocks passed to the class_matchers plugin are evaluated in route
    # block context.
    #
    # This plugin does not work with the params_capturing plugin, as it does not
    # offer the ability to associate block arguments with named keys.
    module ClassMatchers
      def self.configure(app)
        app.opts[:class_matchers] ||= {
          Integer=>[/(\d{1,100})/, /\A\/(\d{1,100})(?=\/|\z)/, :_convert_class_Integer].freeze,
          String=>[/([^\/]+)/, /\A\/([^\/]+)(?=\/|\z)/, nil].freeze
        }
      end

      module InstanceMethods
        private

        def _convert_class_Integer(i)
          if i = @_request.send(:_match_class_convert_Integer, i)
            i
          end
        end
      end

      module ClassMethods
        # Set the matcher and block to use for the given class.
        # The matcher can be a regexp, registered class matcher, or registered symbol
        # matcher (if using the symbol_matchers plugin).
        #
        # If providing a regexp, the block given will be called with all regexp captures.
        # If providing a registered class or symbol, the block will be called with the
        # captures returned by the block for the registered class or symbol, or the regexp
        # captures if no block was registered with the class or symbol. In either case,
        # if a block is given, it should return an array with the captures to yield to
        # the match block.
        def class_matcher(klass, matcher, &block)
          meth = :"_match_class_#{klass}"

          case matcher
          when Regexp
            regexp_matcher = matcher
            regexp = self::RodaRequest.send(:consume_pattern, matcher)
          when Class
            regexp_matcher, regexp, matcher_block = opts[:class_matchers][matcher]
            unless regexp
              raise RodaError, "unregistered class matcher given to class_matcher: #{matcher.inspect}"
            end

            block = merge_class_matcher_blocks(klass, block, matcher_block)
          when Symbol
            unless opts[:symbol_matchers]
              raise RodaError, "cannot provide Symbol matcher to class_matcher unless using symbol_matchers plugin: #{matcher.inspect}"
            end

            regexp_matcher, regexp, matcher_block = opts[:symbol_matchers][matcher]
            unless regexp
              raise RodaError, "unregistered symbol matcher given to class_matcher: #{matcher.inspect}"
            end

            block = merge_class_matcher_blocks(klass, block, matcher_block)
          else
            raise RodaError, "unsupported matcher given to class_matcher: #{matcher.inspect}"
          end

          if block.is_a?(Symbol)
            convert_meth = block
          elsif block
            convert_meth = :"_convert_class_#{klass}"
            define_method(convert_meth, &block)
            private convert_meth
          end

          opts[:class_matchers][klass] = [regexp_matcher, regexp, convert_meth].freeze

          self::RodaRequest.class_eval do
            define_method(meth){consume(regexp, convert_meth)}
            private meth
          end

          nil
        end

        # Freeze the class_matchers hash when freezing the app.
        def freeze
          opts[:class_matchers].freeze
          super
        end

        private

        # If both block and matcher_block are given, return a
        # proc that calls matcher block first, and only calls
        # block with the return values of matcher_block if
        # the matcher_block returns an array.
        # Otherwise, return matcher_block or block.
        def merge_class_matcher_blocks(klass, block, matcher_meth)
          if matcher_meth
            if block
              convert_meth = :"_convert_merge_class_#{klass}"
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
          elsif block
            block
          end
        end
      end
    end

    register_plugin(:class_matchers, ClassMatchers)
  end
end
