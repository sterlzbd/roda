# frozen-string-literal: true

#
class Roda
  module RodaPlugins
    # The yield_response plugin yields +#response+ as an optional second
    # argument to the +route+ block, so you can manipulate it more conveniently:
    #
    #   class App < Roda
    #     plugin :yield_response
    #     route do |req, res|
    #       req.post do
    #         @artist = Artist.create(name: req.params['name'].to_s)
    #         res['Content-Type'] = 'application/json'
    #         res.status = 201
    #         res.write @artist.to_json
    #       end
    #     end
    #   end
    #
    # The plugin runs in compatibility mode by default, which incurs the tiny
    # performance penalty of the +hooks+ plugin. At the cost of compatibility
    # with +hooks+, you can run the +yield_response+ plugin with zero
    # performance penalty by configuring it in fast mode:
    #
    #   class App < Roda
    #     plugin :yield_response, mode: "fast"
    #     plugin :hooks
    #   end
    module YieldResponse
      DEFAULT_OPTIONS = { mode: "compatible" }.freeze

      def self.load_dependencies(app, opts = DEFAULT_OPTIONS)
        if opts[:mode] == "fast"
          app.plugin YieldResponse::Fast
        else
          app.plugin(:hooks)
          app.plugin YieldResponse::Compatible
        end
      end

      # Respect the hooks plugin's call to +_roda_before+
      module Compatible
        module ClassMethods
          def rack_app_route_block(block)
            lambda do |r|
              _roda_before
              instance_exec(r, response, &block)
            end
          end
        end
      end

      # In 'fast' mode, YieldResponse just overrides Roda's default #call,
      # which means it doesn't incur the small performance penalty of
      # +instance_exec+, nor the larger penalty of loading the +hooks+ plugin.
      module Fast
        module InstanceMethods
          def call(&block)
            catch(:halt) do
              req = @_request
              res = @_response
              req.block_result(instance_exec(req, res, &block))
              res.finish
            end
          end
        end
      end
    end

    register_plugin :yield_response, YieldResponse
  end
end
