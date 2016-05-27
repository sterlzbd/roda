# frozen-string-literal: true

#
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
    # You can also set the raw content as the second argument,
    # instead of passing a block:
    #
    #   <% content_for :foo, "Some content" %>
    #
    # In the template in which you want to retrieve content,
    # call content_for without the block:
    #
    #   <%= content_for :foo %>
    module ContentFor
      # Depend on the render plugin, since this plugin only makes
      # sense when the render plugin is used.
      def self.load_dependencies(app, _options = {})
        app.plugin :render
      end

      # Configure wether to append or overwrite. Overwrite is default.
      def self.configure(app, options = {})
        app.opts[:append_content_for] = options[:append] || false
      end

      module InstanceMethods
        # If called with a block, store content enclosed by block
        # under the given key.  If called without a block, retrieve
        # stored content with the given key, or return nil if there
        # is no content stored with that key.
        def content_for(key, value=nil, &block)
          if block
            outvar = render_opts[:template_opts][:outvar]
            buf_was = instance_variable_get(outvar)

            # clean the output buffer for ERB-based rendering systems
            instance_variable_set(outvar, String.new)
            # Render the content.
            content = Tilt[render_opts[:engine]].new(&block).render
            # Restore the output buffer
            instance_variable_set(outvar, buf_was)

            # Store the content.
            @_content_for ||= {}

            if opts[:append_content_for]
              @_content_for[key] ||= []
              @_content_for[key].push content
            else
              @_content_for[key] = content
            end
          elsif value
            @_content_for ||= {}

            if opts[:append_content_for]
              @_content_for[key] ||= []
              @_content_for[key].push value
            else
              @_content_for[key] = value
            end
          elsif @_content_for
            if opts[:append_content_for]
              @_content_for[key].join('') if @_content_for[key]
            else
              @_content_for[key]
            end
          end
        end
      end
    end

    register_plugin(:content_for, ContentFor)
  end
end
