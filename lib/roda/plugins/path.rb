class Roda
  module RodaPlugins
    # The path plugin adds support for named paths.  Using the +path+ class method, you can
    # easily create <tt>*_path</tt> instance methods for each named path.  Those instance
    # methods can then be called if you need to get the path for a form action, link,
    # redirect, or anything else.  Example:
    #
    #   plugin :path
    #   path :foo, '/foo'
    #   path :bar do |bar|
    #     "/bar/#{bar.id}"
    #   end
    #
    #   route do |r|
    #     r.post 'bar' do
    #       bar = Bar.create(r.params['bar'])
    #       r.redirect bar_path(bar)
    #     end
    #   end
    module Path
      module ClassMethods
        def path(name, path=nil, &block)
          raise RodaError,  "cannot provide both path and block to Roda.path" if path && block
          raise RodaError,  "must provide either path or block to Roda.path" unless path || block

          if path
            path = path.dup.freeze
            block = lambda{path}
          end

          define_method("#{name}_path", &block)
        end
      end
    end

    register_plugin(:path, Path)
  end
end
