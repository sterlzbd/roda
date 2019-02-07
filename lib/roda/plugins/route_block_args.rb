# frozen-string-literal: true

#
class Roda
  module RodaPlugins
    # The route_block_args plugin lets you customize what arguments are passed to
    # the +route+ block.  So if you have an application that always needs access
    # to the +response+, the +params+, the +env+, or the +session+, you can use
    # this plugin so that any of those can be arguments to the route block.
    # Example:
    #
    #   class App < Roda
    #     plugin :route_block_args do
    #       [request, request.params, response]
    #     end
    #
    #     route do |r, params, res|
    #       r.post do
    #         artist = Artist.create(name: params['name'].to_s)
    #         res.status = 201
    #         artist.id.to_s
    #       end
    #     end
    #   end
    module RouteBlockArgs
      def self.configure(app, &block)
        app.instance_exec do 
          opts[:route_block_args] = block
          route(&@raw_route_block) if @raw_route_block
        end
      end

      # Override the route block input so that the block
      # given is passed the arguments specified by the
      # block given to the route_block_args plugin.
      module ClassMethods
        private

        def convert_route_block(block)
          proc do |r|
            instance_exec(*instance_exec(&opts[:route_block_args]), &block)
          end
        end
      end
    end

    register_plugin :route_block_args, RouteBlockArgs
  end
end
