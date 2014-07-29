class Roda
  module RodaPlugins
    module Halt
      module RequestMethods
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
