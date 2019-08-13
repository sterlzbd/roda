# frozen-string-literal: true

require_relative 'render'

#
class Roda
  module RodaPlugins
    # The render_each plugin allows you to render a template for each
    # value in an enumerable, returning the concatention of all of the
    # template renderings.  For example:
    #
    #   render_each([1,2,3], :foo)
    #
    # will render the +foo+ template 3 times.  Each time the template
    # is rendered, the local variable +foo+ will contain the given
    # value (e.g. on the first rendering +foo+ is 1).
    #
    # You can pass additional render options via an options hash:
    #
    #   render_each([1,2,3], :foo, views: 'partials')
    #
    # One additional option supported by is +:local+, which sets the
    # local variable containing the current value to use.  So:
    #
    #   render_each([1,2,3], :foo, local: :bar)
    #
    # Will render the +foo+ template, but the local variable used inside
    # the template will be +bar+.  You can use <tt>local: nil</tt> to
    # not set a local variable inside the template.
    module RenderEach
      # Load the render plugin before this plugin, since this plugin
      # calls the render method.
      def self.load_dependencies(app)
        app.plugin :render
      end

      COMPILED_METHOD_SUPPORT = Render::COMPILED_METHOD_SUPPORT
      NO_CACHE = {:cache=>false}.freeze
      ALLOWED_KEYS = [:locals, :local].freeze

      module InstanceMethods
        # For each value in enum, render the given template using the
        # given opts.  The template and options hash are passed to +render+.
        # Additional options supported:
        # :local :: The local variable to use for the current enum value
        #           inside the template.  An explicit +nil+ value does not
        #           set a local variable.  If not set, uses the template name.
        def render_each(enum, template, opts=(no_opts = true; optimized_template = _cached_render_each_template_method(template); OPTS))
          if optimized_template
            as = template.to_s.to_sym
            return enum.map{|v| send(optimized_template, as=>v)}.join
          elsif opts.has_key?(:local)
            as = opts[:local]
          else
            as = template.to_s.to_sym

            if COMPILED_METHOD_SUPPORT &&
               no_opts &&
               optimized_template.nil? &&
               (method_cache = render_opts[:template_method_cache]) &&
               (method_cache_key = _cached_template_method_key([:_render_each, template]))

              template_obj = retrieve_template(render_template_opts(template, NO_CACHE))
              method_name = :"_roda_render_each_#{self.class.object_id}_#{method_cache_key}"

              case template_obj
              when Render::TemplateMtimeWrapper
                optimized_template = method_cache[method_cache_key] = template_obj.define_compiled_method(self.class, method_name, [as])
              else
                begin
                  unbound_method = template_obj.send(:compiled_method, [as])
                rescue ::NotImplementedError
                  method_cache[method_cache_key] = false
                else
                  self.class::RodaCompiledTemplates.send(:define_method, method_name, unbound_method)
                  self.class::RodaCompiledTemplates.send(:private, method_name)
                  optimized_template = method_cache[method_cache_key] = method_name
                end
              end

              if optimized_template
                return enum.map{|v| send(optimized_template, as=>v)}.join
              end
            end
          end

          if as
            opts = opts.dup
            if locals = opts[:locals]
              locals = opts[:locals] = Hash[locals]
            else
              locals = opts[:locals] = {}
            end
          end

          if COMPILED_METHOD_SUPPORT &&
             !no_opts &&
             as &&
             (opts.keys - ALLOWED_KEYS).empty? &&
             (method_cache = render_opts[:template_method_cache])

            locals_keys = (locals.keys << as).sort
            key = [:_render_each, template, locals_keys]

            optimized_template = case template
            when String, Symbol
              _cached_template_method_lookup(method_cache, key)
            else
              false
            end

            case optimized_template
            when Symbol
              return enum.map do |v|
                locals[as] = v
                send(optimized_template, locals)
              end.join
            when false
              # nothing
            else
              if method_cache_key = _cached_template_method_key(key)
                template_obj = retrieve_template(render_template_opts(template, NO_CACHE))
                method_name = :"_roda_render_each_#{self.class.object_id}_#{method_cache_key}"

                case template_obj
                when Render::TemplateMtimeWrapper
                  optimized_template = method_cache[method_cache_key] = template_obj.define_compiled_method(self.class, method_name, locals_keys)
                else
                  begin
                    unbound_method = template_obj.send(:compiled_method, locals_keys)
                  rescue ::NotImplementedError
                    method_cache[method_cache_key] = false
                  else
                    self.class::RodaCompiledTemplates.send(:define_method, method_name, unbound_method)
                    self.class::RodaCompiledTemplates.send(:private, method_name)
                    optimized_template = method_cache[method_cache_key] = method_name
                  end
                end

                if optimized_template
                  return enum.map do |v|
                    locals[as] = v
                    send(optimized_template, locals)
                  end.join
                end
              end
            end
          end

          enum.map do |v|
            locals[as] = v if as
            render_template(template, opts)
          end.join
        end
        
        private

        if COMPILED_METHOD_SUPPORT
          # If compiled method support is enabled in the render plugin, return the
          # method name to call to render the template.  Return false if not given
          # a string or symbol, or if compiled method support for this template has
          # been explicitly disabled.  Otherwise return nil.
          def _cached_render_each_template_method(template)
            case template
            when String, Symbol
              if (method_cache = render_opts[:template_method_cache])
                _cached_template_method_lookup(method_cache, [:_render_each, template])
              end
            else
              false
            end
          end
        else
          # :nocov:
          def _cached_render_each_template_method(template)
            nil
          end
          # :nocov:
        end
      end
    end

    register_plugin(:render_each, RenderEach)
  end
end
