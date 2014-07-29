class Roda
  module RodaPlugins
    # The h plugin adds an +h+ instance method that will HTML
    # escape the input and return it.
    #
    # The following example will return "&lt;foo&gt;" as the body.
    #
    #   plugin :h
    #
    #   route do |r|
    #     h('<foo>')
    #   end
    module H
      module InstanceMethods
        # HTML escape the input and return the escaped version.
        def h(s)
          ::Rack::Utils.escape_html(s.to_s)
        end
      end
    end

    register_plugin(:h, H)
  end
end
