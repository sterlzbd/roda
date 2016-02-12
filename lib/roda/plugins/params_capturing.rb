# frozen-string-literal: true

#
class Roda
  module RodaPlugins
    # The params_capturing plugin makes string and symbol matchers
    # update the request params with the value of the captured segments:
    #
    #   plugin :params_capturing
    #
    #   route do |r|
    #     # GET /foo/123/abc/67
    #     r.on("foo/:bar/:baz", :quux) do
    #       r[:bar] #=> '123'
    #       r[:baz] #=> 'abc'
    #       r[:quux] #=> '67'
    #     end
    #   end
    #
    # Note that this updating of the request params is only done if
    # all arguments to the matcher are symbols or strings.  In all other
    # cases, Roda will not update the params with the captures. So
    # this will not update the request params:
    #
    #   r.on(:x, /(y)/i) do
    #     r[:x] #=> nil
    #   end
    #
    # Note that the param keys are actually stored in +r.params+ as
    # strings and not symbols (<tt>r[]</tt> converts the argument
    # to a string before looking it up in +r.params+).
    module ParamsCapturing
      module RequestMethods
        private

        if RUBY_VERSION >= '1.9'
          # Regexp to scan for capture names. Uses positive lookbehind
          # so it is only valid on ruby 1.9+, hence the use of eval.
          STRING_PARAM_CAPTURE_REGEXP = eval("/(?<=:)\\w+/")

          # Add the capture names from this string to list of param
          # capture names if param capturing.
          def _match_string(str)
            if pc = @_params_captures
              pc.concat(str.scan(STRING_PARAM_CAPTURE_REGEXP))
            end
            super
          end
        else
          # Ruby 1.8 doesn't support positive lookbehind, so include the
          # colon in the scan, and strip it out later.
          STRING_PARAM_CAPTURE_RANGE = 1..-1

          def _match_string(str)
            if pc = @_params_captures
              pc.concat(str.scan(/:\w+/).map{|s| s[STRING_PARAM_CAPTURE_RANGE]})
            end
            super
          end
        end

        # Add the symbol to the list of param capture names if param capturing.
        def _match_symbol(sym)
          if pc = @_params_captures
            pc << sym.to_s
          end
          super
        end

        # If all arguments are strings or symbols, turn on param capturing during
        # the matching, but turn it back off before yielding to the block.  Add
        # any captures to the params based on the param capture names added by
        # the matchers.
        def if_match(args)
          if args.all?{|x| x.is_a?(String) || x.is_a?(Symbol)}
            pc = @_params_captures = []
            params = self.params
            super do |*a|
              @_params_captures = nil
              pc.zip(a).each do |k,v|
                params[k] = v
              end
              yield(*a)
            end
          else
            super
          end
        end
      end
    end

    register_plugin(:params_capturing, ParamsCapturing)
  end
end
