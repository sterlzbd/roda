class Sinuba
  module SinubaPlugins
    module H
      module InstanceMethods
        def h(s)
          Rack::Utils.escape_html(s.to_s)
        end
      end
    end
  end

  register_plugin(:h, SinubaPlugins::H)
end
