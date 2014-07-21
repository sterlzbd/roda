require "tilt"

class Sinuba
  module Render
    class Cache
      MUTEX = Mutex.new

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
      opts[:views] ||= File.expand_path("views", Dir.pwd)
      opts[:layout] ||= "layout"
      opts[:layout_opts] ||= (opts[:layout_opts] || {}).dup
      opts[:opts] ||= (opts[:opts] || {}).dup
      opts[:opts][:outvar] ||= '@_output'
      if RUBY_VERSION >= "1.9"
        opts[:opts][:default_encoding] ||= Encoding.default_external
      end
      opts[:cache] = Cache.new
    end

    module ClassMethods
      def inherited(subclass)
        super
        opts = subclass.opts[:render] = opts[:render].dup
        opts[:layout_opts] = opts[:layout_opts].dup
        opts[:opts] = opts[:opts].dup
        opts[:cache] = Cache.new
      end
    end

    module InstanceMethods
      def render_opts
        opts[:render]
      end

      def view(template, opts={})
        if template.is_a?(Hash)
          opts = template
        end

        content = render(template, opts)

        if opts.fetch(:layout, true)
          if layout_opts = opts[:layout_opts]
            layout_opts = render_opts[:layout_opts].merge(layout_opts)
          end

          content = render(opts[:layout] || render_opts[:layout], layout_opts){content}
        end

        content
      end

      def template_path(template, opts)
        render_opts = render_opts()
        "#{opts[:views] || render_opts[:views]}/#{template}.#{opts[:engine] || render_opts[:engine]}"
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
          opts = template
        end
        render_opts = render_opts()

        if content = opts[:inline]
          path = content
          template_block = Proc.new{content}
          template_class = Tilt[opts[:engine] || render_opts[:engine]]
        else
          template_class = Tilt
          unless path = opts[:path]
            path = template_path(template)
          end
        end

        render_opts[:cache].fetch(path) do
          template_class.new(path, 1, render_opts[:opts].merge(opts), &template_block)
        end.render(self, opts[:locals], &block)
      end
    end
  end

  register_plugin(:render, Render)
end
