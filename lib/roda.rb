require "rack"
require "thread"
require "roda/version"

# The main class for Roda.  Roda is built completely out of plugins, with the
# default plugin being Roda::RodaPlugins::Base, so this class is mostly empty
# except for some constants.
class Roda
  # Error class raised by Roda
  class RodaError < StandardError; end

  if defined?(RUBY_ENGINE) && RUBY_ENGINE != 'ruby'
    # A thread safe cache class, offering only #[] and #[]= methods,
    # each protected by a mutex.  Used on non-MRI where Hash is not
    # thread safe.
    class RodaCache
      # Create a new thread safe cache.
      def initialize
        @mutex = Mutex.new
        @hash = {}
      end

      # Make getting value from underlying hash thread safe.
      def [](key)
        @mutex.synchronize{@hash[key]}
      end

      # Make setting value in underlying hash thread safe.
      def []=(key, value)
        @mutex.synchronize{@hash[key] = value}
      end
    end
  else
    # Hashes are already thread-safe in MRI, due to the GVL, so they
    # can safely be used as a cache.
    RodaCache = Hash
  end

  # Base class used for Roda requests.  The instance methods for this
  # class are added by Roda::RodaPlugins::Base::RequestMethods, the
  # class methods are added by Roda::RodaPlugins::Base::RequestClassMethods.
  class RodaRequest < ::Rack::Request;
    @roda_class = ::Roda
    @match_pattern_cache = ::Roda::RodaCache.new
  end

  # Base class used for Roda responses.  The instance methods for this
  # class are added by Roda::RodaPlugins::Base::ResponseMethods, the class
  # methods are added by Roda::RodaPlugins::Base::ResponseClassMethods.
  class RodaResponse < ::Rack::Response;
    @roda_class = ::Roda
  end

  @builder = ::Rack::Builder.new
  @middleware = []
  @opts = {}

  # Module in which all Roda plugins should be stored. Also contains logic for
  # registering and loading plugins.
  module RodaPlugins
    # Stores registered plugins
    @plugins = RodaCache.new

    # If the registered plugin already exists, use it.  Otherwise,
    # require it and return it.  This raises a LoadError if such a
    # plugin doesn't exist, or a RodaError if it exists but it does
    # not register itself correctly.
    def self.load_plugin(name)
      h = @plugins
      unless plugin = h[name]
        require "roda/plugins/#{name}"
        raise RodaError, "Plugin #{name} did not register itself correctly in Roda::RodaPlugins" unless plugin = h[name]
      end
      plugin
    end

    # Register the given plugin with Roda, so that it can be loaded using #plugin
    # with a symbol.  Should be used by plugin files.
    def self.register_plugin(name, mod)
      @plugins[name] = mod
    end

    # The base plugin for Roda, implementing all default functionality.
    # Methods are put into a plugin so future plugins can easily override
    # them and call super to get the default behavior.
    module Base
      # Class methods for the Roda class.
      module ClassMethods
        # The rack application that this class uses.
        attr_reader :app

        # The settings/options hash for the current class.
        attr_reader :opts

        # Call the internal rack application with the given environment.
        # This allows the class itself to be used as a rack application.
        # However, for performance, it's better to use #app to get direct
        # access to the underlying rack app.
        def call(env)
          app.call(env)
        end

        # Create a match_#{key} method in the request class using the given
        # block, so that using a hash key in a request match method will
        # call the block.  The block should return nil or false to not
        # match, and anything else to match.
        def hash_matcher(key, &block)
          request_module{define_method(:"match_#{key}", &block)}
        end

        # When inheriting Roda, setup a new rack app builder, copy the
        # default middleware and opts into the subclass, and set the
        # request and response classes in the subclasses to be subclasses
        # of the request and responses classes in the parent class.  This
        # makes it so child classes inherit plugins from their parent,
        # but using plugins in child classes does not affect the parent.
        def inherited(subclass)
          super
          subclass.instance_variable_set(:@builder, ::Rack::Builder.new)
          subclass.instance_variable_set(:@middleware, @middleware.dup)
          subclass.instance_variable_set(:@opts, opts.dup)
          
          request_class = Class.new(self::RodaRequest)
          request_class.roda_class = subclass
          request_class.match_pattern_cache = thread_safe_cache
          subclass.const_set(:RodaRequest, request_class)

          response_class = Class.new(self::RodaResponse)
          response_class.roda_class = subclass
          subclass.const_set(:RodaResponse, response_class)
        end

        # Load a new plugin into the current class.  A plugin can be a module
        # which is used directly, or a symbol represented a registered plugin
        # which will be required and then used.
        def plugin(mixin, *args, &block)
          if mixin.is_a?(Symbol)
            mixin = RodaPlugins.load_plugin(mixin)
          end

          if mixin.respond_to?(:load_dependencies)
            mixin.load_dependencies(self, *args, &block)
          end

          if defined?(mixin::InstanceMethods)
            include mixin::InstanceMethods
          end
          if defined?(mixin::ClassMethods)
            extend mixin::ClassMethods
          end
          if defined?(mixin::RequestMethods)
            self::RodaRequest.send(:include, mixin::RequestMethods)
          end
          if defined?(mixin::RequestClassMethods)
            self::RodaRequest.extend mixin::RequestClassMethods
          end
          if defined?(mixin::ResponseMethods)
            self::RodaResponse.send(:include, mixin::ResponseMethods)
          end
          if defined?(mixin::ResponseClassMethods)
            self::RodaResponse.extend mixin::ResponseClassMethods
          end
          
          if mixin.respond_to?(:configure)
            mixin.configure(self, *args, &block)
          end
        end

        # Include the given module in the request class. If a block
        # is provided instead of a module, create a module using the
        # the block.
        def request_module(mod = nil, &block)
          module_include(:request, mod, &block)
        end
    
        # Include the given module in the response class. If a block
        # is provided instead of a module, create a module using the
        # the block.
        def response_module(mod = nil, &block)
          module_include(:response, mod, &block)
        end

        # Setup route definitions for the current class, and build the
        # rack application using the stored middleware.
        def route(&block)
          @middleware.each{|a, b| @builder.use(*a, &b)}
          @builder.run lambda{|env| new.call(env, &block)}
          @app = @builder.to_app
        end

        # A new thread safe cache instance.  This is a method so it can be
        # easily overridden for alternative implementations.
        def thread_safe_cache
          RodaCache.new
        end

        # Add a middleware to use for the rack application.  Must be
        # called before calling #route.
        def use(*args, &block)
          @middleware << [args, block]
        end

        private

        # Backbone of the request_module and response_module support.
        def module_include(type, mod)
          if type == :response
            klass = self::RodaResponse
            iv = :@response_module
          else
            klass = self::RodaRequest
            iv = :@request_module
          end

          if mod
            raise RodaError, "can't provide both argument and block to response_module" if block_given?
            klass.send(:include, mod)
          else
            unless mod = instance_variable_get(iv)
              mod = instance_variable_set(iv, Module.new)
              klass.send(:include, mod)
            end

            mod.module_eval(&Proc.new) if block_given?
          end

          mod
        end
      end

      # Instance methods for the Roda class.
      module InstanceMethods
        SESSION_KEY = 'rack.session'.freeze

        # Create a request and response of the appopriate
        # class, the instance_exec the route block with
        # the request, handling any halts.
        def call(env, &block)
          @_request = self.class::RodaRequest.new(self, env)
          @_response = self.class::RodaResponse.new
          _route(&block)
        end

        # The environment for the current request.
        def env
          request.env
        end

        # The class-level options hash.  This should probably not be
        # modified at the instance level.
        def opts
          self.class.opts
        end

        # The instance of the request class related to this request.
        def request
          @_request
        end

        # The instance of the response class related to this request.
        def response
          @_response
        end

        # The session for the current request.  Raises a RodaError if
        # a session handler has not been loaded.
        def session
          env[SESSION_KEY] || raise(RodaError, "You're missing a session handler. You can get started by adding use Rack::Session::Cookie")
        end

        private

        # Internals of #call, extracted so that plugins can override
        # behavior after the request and response have been setup.
        def _route(&block)
          catch(:halt) do
            request.block_result(instance_exec(@_request, &block))
            response.finish
          end
        end
      end

      # Class methods for RodaRequest
      module RequestClassMethods
        # Reference to the Roda class related to this request class.
        attr_accessor :roda_class

        # The cache to use for match patterns for this request class.
        attr_accessor :match_pattern_cache

        # Return the cached pattern for the given object.  If the object is
        # not already cached, yield to get the basic pattern, and convert the
        # basic pattern to a pattern that does not partial segments.
        def cached_matcher(obj)
          cache = @match_pattern_cache

          unless pattern = cache[obj]
            pattern = cache[obj] = consume_pattern(yield)
          end

          pattern
        end

        # Define a verb method in the given that will yield to the match block
        # if the request method matches and there are either no arguments or
        # there is a successful terminal match on the arguments.
        def def_verb_method(mod, verb)
          mod.class_eval(<<-END, __FILE__, __LINE__+1)
            def #{verb}(*args, &block)
              _verb(args, &block) if #{verb == :get ? :is_get : verb}?
            end
          END
        end

        # Since RodaRequest is anonymously subclassed when Roda is subclassed,
        # and then assigned to a constant of the Roda subclass, make inspect
        # reflect the likely name for the class.
        def inspect
          "#{roda_class.inspect}::RodaRequest"
        end

        private

        # The pattern to use for consuming, based on the given argument.  The returned
        # pattern requires the path starts with a string and does not match partial
        # segments.
        def consume_pattern(pattern)
          /\A(\/(?:#{pattern}))(?=\/|\z)/
        end
      end

      # Instance methods for RodaRequest, mostly related to handling routing
      # for the request.
      module RequestMethods
        PATH_INFO = "PATH_INFO".freeze
        SCRIPT_NAME = "SCRIPT_NAME".freeze
        REQUEST_METHOD = "REQUEST_METHOD".freeze
        EMPTY_STRING = "".freeze
        SLASH = "/".freeze
        SEGMENT = "([^\\/]+)".freeze
        TERM_INSPECT = "TERM".freeze
        GET_REQUEST_METHOD = 'GET'.freeze

        TERM = Object.new
        def TERM.inspect
          TERM_INSPECT
        end
        TERM.freeze

        # The current captures for the request.  This gets modified as routing
        # occurs.
        attr_reader :captures

        # The Roda instance related to this request object.  Useful if routing
        # methods need access to the scope of the Roda route block.
        attr_reader :scope

        # Store the roda instance and environment.
        def initialize(scope, env)
          @scope = scope
          @captures = []
          super(env)
        end

        # As request routing modifies SCRIPT_NAME and PATH_INFO, this exists
        # as a helper method to get the full request of the path info.
        def full_path_info
          "#{env[SCRIPT_NAME]}#{env[PATH_INFO]}"
        end

        # Immediately stop execution of the route block and return the given
        # rack response array of status, headers, and body.  If no argument
        # is given, uses the current response.
        def halt(res=response.finish)
          throw :halt, res
        end

        # Whether this request is a get request.  Similar to the default
        # Rack::Request get? method, but can be overridden without changing
        # rack's behavior.
        def is_get?
          env[REQUEST_METHOD] == GET_REQUEST_METHOD
        end

        # Handle match block return values.  By default, if a string is given
        # and the response is empty, use the string as the response body.
        def block_result(result)
          res = response
          if res.empty? && (body = block_result_body(result))
            res.write(body)
          end
        end

        # Show information about current request, including request class,
        # request method and full path.
        def inspect
          "#<#{self.class.inspect} #{env[REQUEST_METHOD]} #{full_path_info}>"
        end

        # Does a terminal match on the input, matching only if the arguments
        # have fully matched the patch.
        def is(*args, &block)
          if args.empty?
            if env[PATH_INFO] == EMPTY_STRING
              always(&block)
            end
          else
            args << TERM
            if_match(args, &block)
          end
        end

        # Attempts to match on all of the arguments.  If all of the
        # arguments match, control is yielded to the block, and after
        # the block returns, the rack response will be returned.
        # If any of the arguments fails, ensures the request state is
        # returned to that before matches were attempted.
        def on(*args, &block)
          if args.empty?
            always(&block)
          else
            if_match(args, &block)
          end
        end

        # The response related to the current request.
        def response
          scope.response
        end

        # Immediately redirect to the given path.
        def redirect(path, status=302)
          response.redirect(path, status)
          throw :halt, response.finish
        end

        # If this is a GET request for the root ("/"), yield to the match block.
        def root(&block)
          if env[PATH_INFO] == SLASH && is_get?
            always(&block)
          end
        end

        # Call the given rack app with the environment and immediately return
        # the response as the response for this request.
        def run(app)
          throw :halt, app.call(env)
        end

        private

        # Match any of the elements in the given array.  Return at the
        # first match without evaluating future matches.  Returns false
        # if no elements in the array match.
        def _match_array(matcher)
          matcher.any? do |m|
            if matched = match(m)
              if m.is_a?(String)
                captures.push(m)
              end
            end

            matched
          end
        end

        # Match the given regexp exactly if it matches a full segment.
        def _match_regexp(re)
          consume(self.class.cached_matcher(re){re})
        end

        # Match the given hash if all hash matchers match.
        def _match_hash(hash)
          hash.all?{|k,v| send("match_#{k}", v)}
        end

        # Match the given string to the request path.  Regexp escapes the
        # string so that regexp metacharacters are not matched, and recognizes
        # colon tokens for placeholders.
        def _match_string(str)
          consume(self.class.cached_matcher(str){Regexp.escape(str).gsub(/:(\w+)/){|m| _match_symbol_regexp($1)}})
        end

        # Match the given symbol if any segment matches.
        def _match_symbol(sym)
          consume(self.class.cached_matcher(sym){_match_symbol_regexp(sym)})
        end

        # The regular expression to use for matching symbols.  By default, any non-empty
        # segment matches.
        def _match_symbol_regexp(s)
          SEGMENT
        end

        # Backbone of the verb method support, using a terminal match if
        # args is not empty, or a regular match if it is empty.
        def _verb(args, &block)
          if args.empty?
            always(&block)
          else
            args << TERM
            if_match(args, &block)
          end
        end

        # Yield to the match block and return rack response after the block returns.
        def always
          block_result(yield)
          throw :halt, response.finish
        end

        # The body to use for the response if the response does not return
        # a body.  By default, a String is returned directly, and nil is
        # returned otherwise.
        def block_result_body(result)
          if result.is_a?(String)
            result
          end
        end

        # Attempts to match the pattern to the current path.  If there is no
        # match, returns false without changes.  Otherwise, modifies
        # SCRIPT_NAME to include the matched path, removes the matched
        # path from PATH_INFO, and updates captures with any regex captures.
        def consume(pattern)
          return unless matchdata = env[PATH_INFO].match(pattern)

          vars = matchdata.captures

          # Don't mutate SCRIPT_NAME, breaks try
          env[SCRIPT_NAME] += vars.shift
          env[PATH_INFO] = matchdata.post_match

          captures.concat(vars)
        end

        # If all of the arguments match, yields to the match block and
        # returns the rack response when the block returns.  If any of
        # the match arguments doesn't match, does nothing.
        def if_match(args)
          script = env[SCRIPT_NAME]
          path = env[PATH_INFO]

          # For every block, we make sure to reset captures so that
          # nesting matchers won't mess with each other's captures.
          captures.clear

          return unless match_all(args)
          block_result(yield(*captures))
          throw :halt, response.finish
        ensure
          env[SCRIPT_NAME] = script
          env[PATH_INFO] = path
        end
        
        # Attempt to match the argument to the given request, handling
        # common ruby types.
        def match(matcher)
          case matcher
          when String
            _match_string(matcher)
          when Regexp
            _match_regexp(matcher)
          when Symbol
            _match_symbol(matcher)
          when TERM
            env[PATH_INFO] == EMPTY_STRING
          when Hash
            _match_hash(matcher)
          when Array
            _match_array(matcher)
          when Proc
            matcher.call
          else
            matcher
          end
        end

        # Match only if all of the arguments in the given array match.
        def match_all(args)
          args.all?{|arg| match(arg)}
        end

        # Match files with the given extension.  Requires that the
        # request path end with the extension.
        def match_extension(ext)
          consume(self.class.cached_matcher([:extension, ext]){"([^\\/]+?)\.#{ext}\\z"})
        end

        # Match by request method.  This can be an array if you want
        # to match on multiple methods.
        def match_method(type)
          if type.is_a?(Array)
            type.any?{|t| match_method(t)}
          else
            type.to_s.upcase == env[REQUEST_METHOD]
          end
        end

        # Match the given parameter if present, even if the parameter is empty.
        # Adds any match to the captures.
        def match_param(key)
          if v = self[key]
            captures << v
          end
        end

        # Match the given parameter if present and not empty.
        # Adds any match to the captures.
        def match_param!(key)
          if (v = self[key]) && !v.empty?
            captures << v
          end
        end
      end

      # Class methods for RodaResponse
      module ResponseClassMethods
        # Reference to the Roda class related to this response class.
        attr_accessor :roda_class

        # Since RodaResponse is anonymously subclassed when Roda is subclassed,
        # and then assigned to a constant of the Roda subclass, make inspect
        # reflect the likely name for the class.
        def inspect
          "#{roda_class.inspect}::RodaResponse"
        end
      end

      # Instance methods for RodaResponse
      module ResponseMethods
        CONTENT_LENGTH = "Content-Length".freeze
        CONTENT_TYPE = "Content-Type".freeze
        DEFAULT_CONTENT_TYPE = "text/html".freeze
        LOCATION = "Location".freeze

        # The status code to use for the response.  If none is given, will use 200
        # code for non-empty responses and a 404 code for empty responses.
        attr_accessor :status

        # The hash of response headers for the current response.
        attr_reader :headers

        # Set the default headers when creating a response.
        def initialize
          @status  = nil
          @headers = default_headers
          @body    = []
          @length  = 0
        end

        # Return the response header with the given key.
        def [](key)
          @headers[key]
        end

        # Set the response header with the given key to the given value.
        def []=(key, value)
          @headers[key] = value
        end

        # Show response class, status code, response headers, and response body
        def inspect
          "#<#{self.class.inspect} #{@status.inspect} #{@headers.inspect} #{@body.inspect}>"
        end

        # The default headers to use for responses.
        def default_headers
          {CONTENT_TYPE => DEFAULT_CONTENT_TYPE}
        end

        # Modify the headers to include a Set-Cookie value that
        # deletes the cookie.  A value hash can be provided to
        # override the default one used to delete the cookie.
        def delete_cookie(key, value = {})
          ::Rack::Utils.delete_cookie_header!(@headers, key, value)
        end

        # Whether the response body has been written to yet.  Note
        # that writing an empty string to the response body marks
        # the response as not empty.
        def empty?
          @body.empty?
        end

        # Return the rack response array of status, headers, and body
        # for the current response.
        def finish
          b = @body
          s = (@status ||= b.empty? ? 404 : 200)
          [s, @headers, b]
        end

        # Set the Location header to the given path, and the status
        # to the given status.
        def redirect(path, status = 302)
          @headers[LOCATION] = path
          @status  = status
        end

        # Set the cookie with the given key in the headers.
        def set_cookie(key, value)
          ::Rack::Utils.set_cookie_header!(@headers, key, value)
        end

        # Write to the response body.  Updates Content-Length header
        # with the size of the string written.  Returns nil.
        def write(str)
          s = str.to_s

          @length += s.bytesize
          @headers[CONTENT_LENGTH] = @length.to_s
          @body << s
          nil
        end
      end
    end
  end

  extend RodaPlugins::Base::ClassMethods
  plugin RodaPlugins::Base
  RodaRequest.def_verb_method(RodaPlugins::Base::RequestMethods, :get)
  RodaRequest.def_verb_method(RodaPlugins::Base::RequestMethods, :post)
end
