class Roda
  module RodaPlugins
    module H
      module InstanceMethods
        def h(s)
          Rack::Utils.escape_html(s.to_s)
        end
      end
    end
  end

  register_plugin(:h, RodaPlugins::H)
end
