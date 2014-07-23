class Sinuba
  module SinubaPlugins
    module Pass
      module RequestMethods
        def on(*)
          catch(:pass){super}
        end
      end
      module InstanceMethods
        def pass
          throw :pass
        end
      end
    end
  end

  register_plugin(:pass, SinubaPlugins::Pass)
end
