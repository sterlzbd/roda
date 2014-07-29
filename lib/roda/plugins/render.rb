require "tilt"

class Roda
  module RodaPlugins
    # The render plugin adds support for template rendering using the tilt
    # library.  Two methods are provided for template rendering, +view+
    # (which uses the layout) and +render+ (which does not).
    #
    #   plugin :render
    #
    #   route do |r|
    #     r.is 'foo' do
    #       view('foo') # renders views/foo.erb inside views/layout.erb
    #     end
    #
    #     r.is 'bar' do
    #       render('bar') # renders views/bar.erb
    #     end
    #   end
    #
    # You can provide options to the plugin method, or later by modifying
    # +render_opts+.
    #
    #   plugin :render, :engine=>'haml'
    #
    #   render_opts[:views] = 'admin_views'
    #
    # The following options are supported:
    #
    # :cache :: A specific cache to store templates in, or nil/false to not
    #           cache templates (useful for development), defaults to true to
    #           automatically use the default template cache.
    # :engine :: The tilt engine to use for rendering, defaults to 'erb'.
    # :ext :: The file extension to assume for view files, defaults to the :engine
    #         option.
    # :layout :: The base name of the layout file, defaults to 'layout'.
    # :layout_opts :: The options to use when rendering the layout, if different
    #                 from the default options.
    # :opts :: The tilt options used when rendering templates, defaults to
    #          {:outvar=>'@_out_buf'}.
    # :views :: The directory holding the view files, defaults to 'views' in the
    #           current directory.
    #
    # Most of these options can be overridden at runtime by passing options
    # to the +view+ or +render+ methods:
    #
    #   view('foo', :ext=>'html.erb')
    #   render('foo', :views=>'admin_views')
    #
    # There are a couple of additional options to +view+ and +render+ that are
    # available at runtime:
    #
    # :inline :: Use the value given as the template code, instead of looking
    #            for template code in a file.
    # :locals :: Hash of local variables to make available inside the template.
    # :path :: Use the value given as the full pathname for the file, instead
    #          of using the :views and :ext option in combination with the
    #          template name.
    #
    # Here's how those options are used:
    #
    #   view(:inline=>'<%= @foo %>')
    #   render(:path=>'/path/to/template.erb')
    #
    # If you pass a hash as the first argument to +view+ or +render+, it should
    # have either +:inline+ or +:path+ as one of the keys.
    module Render
      # Default template cache.  Thread-safe so that multiple threads can
      # simultaneously use the cache.
      class Cache
        # Mutex used to synchronize access to the cache.  Uses a
        # singleton mutex to reduce memory.
        MUTEX = ::Mutex.new

        # Initialize the cache.
        def initialize
          MUTEX.synchronize{@cache = {}}
        end
        
        # Clear the cache.
        alias clear initialize

        # If the template is found in the cache under the given key,
        # return it, otherwise yield to get the template, and
        # store the template under the given key
        def fetch(key)
          unless template = MUTEX.synchronize{@cache[key]}
            template = yield
            MUTEX.synchronize{@cache[key] = template}
          end

          template
        end
      end

      # Setup default rendering options.  See Render for details.
      def self.configure(app, opts={})
        opts = app.opts[:render] = opts.dup
        opts[:engine] ||= "erb"
        opts[:ext] = nil unless opts.has_key?(:ext) 
        opts[:views] ||= File.expand_path("views", Dir.pwd)
        opts[:layout] = "layout" unless opts.has_key?(:layout)
        opts[:layout_opts] ||= (opts[:layout_opts] || {}).dup
        opts[:opts] ||= (opts[:opts] || {}).dup
        opts[:opts][:outvar] ||= '@_out_buf'
        if RUBY_VERSION >= "1.9"
          opts[:opts][:default_encoding] ||= Encoding.default_external
        end
        cache = opts.fetch(:cache, true)
        opts[:cache] = Cache.new if cache == true
      end

      module ClassMethods
        # Copy the rendering options into the subclass, duping
        # them as necessary to prevent changes in the subclass
        # affecting the parent class.
        def inherited(subclass)
          super
          opts = subclass.opts[:render] = render_opts.dup
          opts[:layout_opts] = opts[:layout_opts].dup
          opts[:opts] = opts[:opts].dup
          opts[:cache] = Cache.new if opts[:cache]
        end

        # Return the render options for this class.
        def render_opts
          opts[:render]
        end
      end

      module InstanceMethods
        # Return the render options for the instance's class.
        def render_opts
          self.class.render_opts
        end

        # Render the given template.  If there is a default layout
        # for the class, take the result of the template rendering
        # and render it inside the layout.  See Render for details.
        def view(template, opts={})
          if template.is_a?(Hash)
            if opts.empty?
              opts = template
            else
              opts = opts.merge(template)
            end
          end

          content = render(template, opts)

          if layout = opts.fetch(:layout, render_opts[:layout])
            if layout_opts = opts[:layout_opts]
              layout_opts = render_opts[:layout_opts].merge(layout_opts)
            end

            content = render(layout, layout_opts||{}){content}
          end

          content
        end

        # Render the given template. See Render for details.
        def render(template, opts = {}, &block)
          if template.is_a?(Hash)
            if opts.empty?
              opts = template
            else
              opts = opts.merge(template)
            end
          end
          render_opts = render_opts()

          if content = opts[:inline]
            path = content
            template_block = Proc.new{content}
            template_class = ::Tilt[opts[:engine] || render_opts[:engine]]
          else
            template_class = ::Tilt
            unless path = opts[:path]
              path = template_path(template, opts)
            end
          end

          cached_template(path) do
            template_class.new(path, 1, render_opts[:opts].merge(opts), &template_block)
          end.render(self, opts[:locals], &block)
        end

        private

        # If caching templates, attempt to retrieve the template from the cache.  Otherwise, just yield
        # to get the template.
        def cached_template(path, &block)
          if cache = render_opts[:cache]
            cache.fetch(path, &block)
          else
            yield
          end
        end

        # The path for the given template.
        def template_path(template, opts)
          render_opts = render_opts()
          "#{opts[:views] || render_opts[:views]}/#{template}.#{opts[:ext] || render_opts[:ext] || render_opts[:engine]}"
        end
      end
    end

    register_plugin(:render, Render)
  end
end
