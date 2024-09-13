# frozen-string-literal: true

#
class Roda
  module RodaPlugins
    module SymbolClassMatchers_
      module ClassMethods
        private

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
        def _symbol_class_matcher(expected_class, obj, matcher, block, &request_class_block)
          unless obj.is_a?(expected_class)
            raise RodaError, "Invalid type passed to class_matcher or symbol_matcher: #{matcher.inspect}"
          end

          if obj.is_a?(Symbol)
            type = "symbol"
            meth = :"match_symbol_#{obj}"
          else
            type = "class"
            meth = :"_match_class_#{obj}"
          end

          case matcher
          when Regexp
            regexp = matcher
            consume_regexp = self::RodaRequest.send(:consume_pattern, regexp)
          when Symbol
            unless opts[:symbol_matchers]
              raise RodaError, "cannot provide Symbol matcher to class_matcher unless using symbol_matchers plugin: #{matcher.inspect}"
            end

            regexp, consume_regexp, matcher_block = opts[:symbol_matchers][matcher]

            unless regexp
              raise RodaError, "unregistered symbol matcher given to #{type}_matcher: #{matcher.inspect}"
            end

            block = _merge_matcher_blocks(type, obj, block, matcher_block)
          when Class
            unless opts[:class_matchers]
              raise RodaError, "cannot provide Class matcher to symbol_matcher unless using class_matchers plugin: #{matcher.inspect}"
            end

            regexp, consume_regexp, matcher_block = opts[:class_matchers][matcher]
            unless regexp
              raise RodaError, "unregistered class matcher given to #{type}_matcher: #{matcher.inspect}"
            end
            block = _merge_matcher_blocks(type, obj, block, matcher_block)
          else
            raise RodaError, "unsupported matcher given to #{type}_matcher: #{matcher.inspect}"
          end

          if block.is_a?(Symbol)
            convert_meth = block
          elsif block
            convert_meth = :"_convert_#{type}_#{obj}"
            define_method(convert_meth, &block)
            private convert_meth
          end

          array = opts[:"#{type}_matchers"][obj] = [regexp, consume_regexp, convert_meth].freeze

          self::RodaRequest.class_eval do
            class_exec(meth, array, &request_class_block)
            private meth
          end

          nil
        end

        # If both block and matcher_block are given, return a
        # proc that calls matcher block first, and only calls
        # block with the return values of matcher_block if
        # the matcher_block returns an array.
        # Otherwise, return matcher_block or block.
        def _merge_matcher_blocks(type, obj, block, matcher_meth)
          if matcher_meth
            if block
              convert_meth = :"_convert_merge_#{type}_#{obj}"
              define_method(convert_meth, &block)
              private convert_meth

              proc do |*a|
                if captures = send(matcher_meth, *a)
                  if captures.is_a?(Array)
                    send(convert_meth, *captures)
                  else
                    send(convert_meth, captures)
                  end
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
    end

    register_plugin(:_symbol_class_matchers, SymbolClassMatchers_)
  end
end

