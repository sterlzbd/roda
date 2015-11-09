class Roda
  module RodaPlugins
    # The content_for plugin is designed to be used with the
    # render plugin, allowing you to store content inside one
    # template, and retrieve that content inside a separate
    # template.  Most commonly, this is so view templates
    # can set content for the layout template to display outside
    # of the normal content pane.
    #
    # In the template in which you want to store content, call
    # content_for with a block:
    #
    #   <% content_for :foo do %>
    #     Some content here.
    #   <% end %>
    #
    # In the template in which you want to retrieve content,
    # call content_for without the block:
    #
    #   <%= content_for :foo %>
    module ContentFor
      # Depend on the render plugin, since this plugin only makes
      # sense when the render plugin is used.
      def self.load_dependencies(app)
        app.plugin :render
      end

      module InstanceMethods
        # If called with a block, store content enclosed by block
        # under the given key.  If called without a block, retrieve
        # stored content with the given key, or return nil if there
        # is no content stored with that key.
        def content_for(key, &block)
          if block
            # clean the output buffer for ERB-based rendering systems
            buf_was = output_buffer
            set_output_buffer ''

            @_content_for ||= {}
            @_content_for[key] = content_render(&block)

            set_output_buffer buf_was
          elsif @_content_for
            @_content_for[key]
          end
        end

        private

        def content_render(&block)
          engine = template_engine.new &block
          engine.render
        end

        def output_buffer
          instance_variable_get(outvar_name)
        end

        def set_output_buffer(value)
          instance_variable_set(outvar_name, value)
        end

        def outvar_name
          render_opts[:template_opts][:outvar]
        end

        def template_engine
          Tilt[render_opts[:engine]]
        end
      end
    end

    register_plugin(:content_for, ContentFor)
  end
end
