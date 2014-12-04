class Roda
  module RodaPlugins
    # The named_templates plugin allows you to specify templates by name,
    # providing the template code to use for a given name:
    #
    #   plugin :named_templates
    #
    #   template :layout do
    #     "<html><body><%= yield %></body></html>"
    #   end
    #   template :index do
    #     "<p>Hello <%= @user %>!</p>"
    #   end
    #
    #   route do |r|
    #     @user = 'You'
    #     render(:index)
    #   end
    #   # => "<html><body><p>Hello You!</p></body></html>"
    #
    # You can provide options for the template, for example to change the
    # engine that the template uses:
    #
    #   template :index, :engine=>:str do
    #     "<p>Hello #{@user}!</p>"
    #   end
    #   
    # The block you use is reevaluted on every call, allowing you to easily
    # include additional setup logic:
    #
    #   template :index do
    #     greeting = ['hello', 'hi', 'howdy'].sample
    #     @user.downcase!
    #     "<p>#{greating} <%= @user %>!</p>"
    #   end
    #   
    # This plugin also works with the view_subdirs plugin, as long as you
    # prefix the template name with the view subdirectory:
    #
    #   template "main/index" do
    #     "<html><body><%= yield %></body></html>"
    #   end
    #
    #   route do |r|
    #     set_view_subdir("main")
    #     @user = 'You'
    #     render(:index)
    #   end
    module NamedTemplates
      # Depend on the render plugin
      def self.load_dependencies(app)
        app.plugin :render
      end

      # Initialize the storage for named templates.
      def self.configure(app)
        app.opts[:named_templates] ||= {}
      end

      module ClassMethods
        # Store a new template block and options for the given template name.
        def template(name, options=nil, &block)
          opts[:named_templates][name.to_s] = [options, block]
          nil
        end

        # Dup the named templates into the subclass, so that adding named
        # templates to the subclass doesn't affect the parent class and
        # vice versa.
        def inherited(subclass)
          super
          subclass.opts[:named_templates] = opts[:named_templates].dup
        end
      end

      module InstanceMethods
        private

        # If a template name is given and it matches a named template, call
        # the named template block to get the inline template to use.
        def find_template(template, options)
          if template && (template_opts, block = opts[:named_templates][template_name(template)]; block)
            if template_opts
              options = template_opts.merge(options)
            else
              options = options.dup
            end

            options[:inline] = instance_exec(&block)

            super(nil, options)
          else
            super
          end
        end
      end
    end

    register_plugin(:named_templates, NamedTemplates)
  end
end
