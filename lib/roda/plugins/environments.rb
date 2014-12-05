class Roda
  module RodaPlugins
    # The environments plugin adds a environment class accessor to get
    # the environment for the application, 3 predicate class methods
    # to check for the current environment (development?, test? and
    # production?), and a class configure method that takes environment(s)
    # and yields to the block if the given environment(s) match the
    # current environment.
    #
    # The default environment for the application is based on
    # ENV['RACK_ENV'].
    #
    # Example:
    #
    #   class Roda
    #     plugin :environments
    #
    #     environment  # => :development
    #     development? # => true
    #     test?        # => false
    #     production?  # => false
    #
    #     # Set the environment for the application
    #     self.environment = :test 
    #     test?        # => true
    #
    #     configure do
    #       # called, as no environments given
    #     end
    #
    #     configure :development, :production do
    #       # not called, as no environments match
    #     end
    #
    #     configure :test do
    #       # called, as environment given matches current environment
    #     end
    #   end
    module Environments
      # Set the environment to use for the app.  Default to ENV['RACK_ENV']
      # if no environment is given.  If ENV['RACK_ENV'] is not set and
      # no environment is given, assume the development environment.
      def self.configure(app, env=ENV["RACK_ENV"])
        app.environment = (env || 'development').to_sym
      end

      module ClassMethods
        # The current environment for the application, which should be stored
        # as a symbol.
        attr_accessor :environment

        # If no environments are given or one of the given environments
        # matches the current environment, yield the receiver to the block.
        def configure(*envs)
          if envs.empty? || envs.any?{|s| s == environment}
            yield self
          end
        end

        [:development, :test, :production].each do |env|
          define_method("#{env}?"){environment == env}
        end
      end
    end

    register_plugin(:environments, Environments)
  end
end
