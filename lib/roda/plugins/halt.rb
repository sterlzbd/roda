class Roda
  module RodaPlugins
    # The halt plugin augments the standard request +halt+ method to handle more than
    # just rack response arrays.
    #
    # After loading the halt plugin:
    #
    #   plugin :halt
    #
    # You can call halt with no arguments to immediately stop processing:
    #
    #   route do |r|
    #     r.halt
    #   end
    #
    # You can call the halt method with an integer to set the response status and return:
    #   
    #   route do |r|
    #     r.halt(403)
    #   end
    #
    # Or set the response body and return:
    #
    #   route do |r|
    #     r.halt("body')
    #   end
    #
    # Or set both:
    #
    #   route do |r|
    #     r.halt(403, "body')
    #   end
    #
    # Or set response status, headers, and body:
    #
    #   route do |r|
    #     r.halt(403, {'Content-Type'=>'text/csv'}, "body')
    #   end
    #
    # Note that there is a difference between provide status, headers, and body as separate
    # arguments and providing them as a rack response array.  With a rack response array,
    # the values are used directly, while with 3 arguments, the headers given are merged into
    # the existing headers and the given body is written to the existing response body.
    module Halt
      module RequestMethods
        # Expand default halt method to handle status codes, headers, and bodies.  See Halt.
        def halt(*res)
          case res.length
          when 0 # do nothing
          when 1
            case v = res[0]
            when Integer
              response.status = v
            when String
              response.write v
            when Array
              super
            else
              raise Roda::RodaError, "singular argument to #halt must be Integer, String, or Array"
            end
          when 2
            response.status = res[0]
            response.write res[1]
          when 3
            response.status = res[0]
            response.headers.merge!(res[1])
            response.write res[2]
          else
            raise Roda::RodaError, "too many arguments given to #halt (accepts 0-3, received #{res.length})"
          end

          _halt response.finish
        end
      end
    end

    register_plugin(:halt, Halt)
  end
end
