class Roda
  module RodaPlugins
    module Pass
      module RequestMethods
        def on(*)
          catch(:pass){super}
        end

        def pass
          throw :pass
        end
      end
    end

    register_plugin(:pass, Pass)
  end
end
