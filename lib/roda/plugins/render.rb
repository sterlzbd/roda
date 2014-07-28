require "tilt"

class Roda
  module RodaPlugins
    module Render
      class Cache
        MUTEX = ::Mutex.new

        def initialize
          MUTEX.synchronize{@cache = {}}
        end
        alias clear initialize

        def fetch(*key)
          unless template = MUTEX.synchronize{@cache[key]}
            template = yield
            MUTEX.synchronize{@cache[key] = template}
          end

          template
        end
      end

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
        def inherited(subclass)
          super
          opts = subclass.opts[:render] = render_opts.dup
          opts[:layout_opts] = opts[:layout_opts].dup
          opts[:opts] = opts[:opts].dup
          opts[:cache] = Cache.new if opts[:cache]
        end

        def render_opts
          opts[:render]
        end
      end

      module InstanceMethods
        def render_opts
          self.class.render_opts
        end

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

        # Render any type of template file supported by Tilt.
        #
        # @example
        #
        #   # Renders home, and is assumed to be HAML.
        #   render("home.haml")
        #
        #   # Renders with some local variables
        #   render("home.haml", site_name: "My Site")
        #
        #   # Renders with HAML options
        #   render("home.haml", {}, ugly: true, format: :html5)
        #
        #   # Renders in layout
        #   render("layout.haml") { render("home.haml") }
        #
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

        def cached_template(path, &block)
          if cache = render_opts[:cache]
            cache.fetch(path, &block)
          else
            yield
          end
        end

        def template_path(template, opts)
          render_opts = render_opts()
          "#{opts[:views] || render_opts[:views]}/#{template}.#{opts[:ext] || render_opts[:ext] || render_opts[:engine]}"
        end
      end
    end
  end

  register_plugin(:render, RodaPlugins::Render)
end
