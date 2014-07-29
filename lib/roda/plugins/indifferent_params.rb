class Roda
  module RodaPlugins
    module IndifferentParams
      module InstanceMethods
        def params
          @_params ||= indifferent_params(request.params)
        end

        private

        def indifferent_params(params)
          case params 
          when Hash
            h = Hash.new{|h, k| h[k.to_s] if Symbol === k}
            params.each{|k, v| h[k] = indifferent_params(v)}
            h
          when Array
            params.map{|x| indifferent_params(x)}
          else
            params
          end
        end
      end  
    end

    register_plugin(:indifferent_params, IndifferentParams)
  end
end
