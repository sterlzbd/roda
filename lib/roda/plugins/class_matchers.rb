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
    # You can register a Date class matcher for that regexp (note that
    # the block must return an array):
    #
    #   class_matcher(Date, /(\d\d\d\d)-(\d\d)-(\d\d)/) do |y, m, d|
    #     [Date.new(y.to_i, m.to_i, d.to_i)]
    #   end
    #
    # And then use the Date class as a matcher, and it will yield a Date object:
    #
    #   r.on Date do |date|
    #     # ...
    #   end
    #
    # This is useful to DRY up code if you are using the same type of pattern and
    # type conversion in multiple places in your application.
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
    #     [Date.new(y, m, d)] if Date.valid_date?(y, m, d)
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
    # This plugin does not work with the params_capturing plugin, as it does not
    # offer the ability to associate block arguments with named keys.
    module ClassMatchers
      def self.configure(app)
        app.opts[:class_matchers] ||= {
          Integer=>[/(\d{1,100})/, /\A\/(\d{1,100})(?=\/|\z)/, proc{|i| if i = app.match_class_convert_Integer(i); [i] end}].freeze,
          String=>[/([^\/]+)/, /\A\/([^\/]+)(?=\/|\z)/, nil].freeze
        }
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
          opts = self.opts
          self::RodaRequest.class_eval do
            case matcher
            when Regexp
              regexp_matcher = matcher
              regexp = consume_pattern(matcher)
              define_method(meth){consume(regexp, &block)}
            when Class
              regexp_matcher, regexp, matcher_block = opts[:class_matchers][matcher]
              unless regexp
                raise RodaError, "unregistered class matcher given to class_matcher: #{matcher.inspect}"
              end

              block = merge_class_matcher_blocks(block, matcher_block)
              define_method(meth){consume(regexp, &block)}
            when Symbol
              unless opts[:symbol_matchers]
                raise RodaError, "cannot provide Symbol matcher to class_matcher unless using symbol_matchers plugin: #{matcher.inspect}"
              end

              regexp_matcher, regexp, matcher_block = opts[:symbol_matchers][matcher]
              unless regexp
                raise RodaError, "unregistered symbol matcher given to class_matcher: #{matcher.inspect}"
              end

              block = merge_class_matcher_blocks(block, matcher_block)
              define_method(meth){consume(regexp, &block)}
            else
              raise RodaError, "unsupported matcher given to class_matcher: #{matcher.inspect}"
            end

            private meth
            opts[:class_matchers][klass] = [regexp_matcher, regexp, block].freeze
            nil
          end
        end

        # Integrate with the Integer_matcher_max plugin.
        def match_class_convert_Integer(i)
          return super if defined?(super)
          i.to_i
        end

        # Freeze the class_matchers hash when freezing the app.
        def freeze
          opts[:class_matchers].freeze
          super
        end
      end

      module RequestClassMethods
        private

        # If both block and matcher_block are given, return a
        # proc that calls matcher block first, and only calls
        # block with the return values of matcher_block if
        # the matcher_block returns an array.
        # Otherwise, return matcher_block or block.
        def merge_class_matcher_blocks(block, matcher_block)
          if matcher_block
            if block
              proc do |*a|
                if captures = matcher_block.call(*a)
                  block.call(*captures)
                end
              end
            else
              matcher_block
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
