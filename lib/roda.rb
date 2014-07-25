require "rack"
require "thread"

class Roda
  RodaVersion = '0.9.0'.freeze

  class RodaError < StandardError; end

  class RodaRequest < Rack::Request; end

  class RodaResponse < Rack::Response; end

  @builder = Rack::Builder.new
  @middleware = []
  @plugins = {}
  @opts = {}

  module RodaPlugins
    module Base
      module ClassMethods
        MUTEX = Mutex.new

        attr_reader :app
        attr_reader :opts

        def call(env)
          app.call(env)
        end

        def define(&block)
          klass = Class.new(self)
          klass.class_eval(&block)
          klass
        end

        def inherited(subclass)
          super
          subclass.instance_variable_set(:@builder, Rack::Builder.new)
          subclass.instance_variable_set(:@middleware, @middleware.dup)
          subclass.instance_variable_set(:@opts, opts.dup)
          subclass.const_set(:RodaRequest, Class.new(self::RodaRequest))
          subclass.const_set(:RodaResponse, Class.new(self::RodaResponse))
        end

        def plugin(mixin, *args, &block)
          if mixin.is_a?(Symbol)
            mixin = load_plugin(mixin)
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
          if defined?(mixin::ResponseMethods)
            self::RodaResponse.send(:include, mixin::ResponseMethods)
          end
          
          if mixin.respond_to?(:configure)
            mixin.configure(self, *args, &block)
          end
        end

        def request(env)
          self::RodaRequest.new(self::RodaResponse.new, env)
        end

        def route(&block)
          @middleware.each{|a, b| @builder.use(*a, &b)}
          @builder.run lambda{|env| new.call(env, &block)}
          @app = @builder.to_app
        end

        def use(*args, &block)
          @middleware << [args, block]
        end

        private

        def load_plugin(name)
          h = Roda.instance_variable_get(:@plugins)
          unless plugin = MUTEX.synchronize{h[name]}
            require "roda/plugins/#{name}"
            raise RodaError, "Plugin #{name} did not register itself correctly in Roda::Plugins" unless plugin = MUTEX.synchronize{h[name]}
          end
          plugin
        end

        def register_plugin(name, mod)
          h = Roda.instance_variable_get(:@plugins)
          MUTEX.synchronize{h[name] = mod}
        end
      end

      module InstanceMethods
        def opts
          self.class.opts
        end

        def env
          request.env
        end

        def request
          @_request
        end

        def response
          request.response
        end

        def call(env, &block)
          @_request = self.class.request(env)
          _route(&block)
        end

        def session
          env["rack.session"] || raise(RodaError, "You're missing a session handler. You can get started by adding use Rack::Session::Cookie")
        end

        private

        def _route(&block)
          catch(:halt) do
            instance_exec(@_request, &block)
            response.finish
          end
        end
      end

      module RequestMethods
        PATH_INFO = "PATH_INFO".freeze
        SCRIPT_NAME = "SCRIPT_NAME".freeze
        TERM = {:term=>true}.freeze
        SEGMENT = "([^\\/]+)".freeze

        attr_reader :response

        attr_reader :captures

        def initialize(response, env)
          @response = response
          @captures = []
          super(env)
        end

        # The heart of the path / verb / any condition matching.
        #
        # @example
        #
        #   on get do
        #     res.write "GET"
        #   end
        #
        #   on get, "signup" do
        #     res.write "Signup"
        #   end
        #
        #   on "user/:id" do |uid|
        #     res.write "User: #{uid}"
        #   end
        #
        #   on "styles", extension("css") do |file|
        #     res.write render("styles/#{file}.sass")
        #   end
        #
        def on(*args, &block)
          try do
            # We stop evaluation of this entire matcher unless
            # each and every `arg` defined for this matcher evaluates
            # to a non-false value.
            #
            # Short circuit examples:
            #    on true, false do
            #
            #    # PATH_INFO=/user
            #    on true, "signup"
            return unless args.all?{|arg| match(arg)}

            # The captures we yield here were generated and assembled
            # by evaluating each of the `arg`s above. Most of these
            # are carried out by #consume.
            body = yield(*captures)

            res = response
            if body.is_a?(String) && res.empty?
              res.write(body)
            end

            halt res.finish
          end
        end

        # @private Used internally by #on to ensure that SCRIPT_NAME and
        #          PATH_INFO are reset to their proper values.
        def try
          script = env[SCRIPT_NAME]
          path = env[PATH_INFO]

          # For every block, we make sure to reset captures so that
          # nesting matchers won't mess with each other's captures.
          captures.clear

          yield

        ensure
          env[SCRIPT_NAME] = script
          env[PATH_INFO] = path
        end
        private :try

        def consume(pattern)
          matchdata = env[PATH_INFO].match(/\A(\/(?:#{pattern}))(\/|\z)/)

          return false unless matchdata

          vars = matchdata.captures

          # Don't mutate SCRIPT_NAME, breaks try
          env[SCRIPT_NAME] += vars.shift
          env[PATH_INFO] = "#{vars.pop}#{matchdata.post_match}"

          captures.concat(vars)
        end

        def match(matcher)
          case matcher
          when String
            consume(matcher.gsub(/:\w+/, SEGMENT))
          when Regexp
            consume(matcher)
          when Symbol
            consume(SEGMENT)
          when Hash
            matcher.all?{|k,v| send("match_#{k}", v)}
          when Array
            matcher.any? do |m|
              if matched = match(m)
                if m.is_a?(String)
                  captures.push(m)
                end
              end
              matched
            end
          when Proc
            matcher.call
          else
            matcher
          end
        end

        # A matcher for files with a certain extension.
        #
        # @example
        #   # PATH_INFO=/style/app.css
        #   on "style", extension("css") do |file|
        #     res.write file # writes app
        #   end
        def match_extension(ext)
          consume("([^\\/]+?)\.#{ext}\\z")
        end

        # Used to ensure that certain request parameters are present. Acts like a
        # precondition / assertion for your route.
        #
        # @example
        #   # POST with data like user[fname]=John&user[lname]=Doe
        #   on "signup", param("user") do |atts|
        #     User.create(atts)
        #   end
        def match_param(key)
          if v = self[key]
            captures << v
          end
        end

        def match_param!(key)
          if (v = self[key]) && !v.empty?
            captures << v
          end
        end

        def match_term(term)
          !(term ^ (env[PATH_INFO] == ""))
        end

        def match_method(type)
          if type.is_a?(Array)
            type.any?{|t| match_method(t)}
          else
            type.to_s.upcase == env['REQUEST_METHOD']
          end
        end

        def is(*args, &block)
          args << TERM
          on(*args, &block)
        end

        # Syntatic sugar for providing HTTP Verb matching.
        #
        # @example
        #   on get, "signup" do
        #   end
        #
        #   on post, "signup" do
        #   end
        def get(*args, &block)
          is_or_on(*args, &block) if get?
        end
        def post(*args, &block)
          is_or_on(*args, &block) if post?
        end

        # If you want to halt the processing of an existing handler
        # and continue it via a different handler.
        #
        # @example
        #   def redirect(*args)
        #     run Roda.define{route{|r| r.on(true){r.redirect(*args)}}}.app
        #   end
        #
        #   on "account" do
        #     redirect "/login" unless session["uid"]
        #
        #     res.write "Super secure account info."
        #   end
        def run(app)
          halt app.call(env)
        end

        def halt(response)
          throw :halt, response
        end

        def redirect(path, status=302)
          response.redirect(path, status)
          halt response.finish
        end

        private

        def is_or_on(*args, &block)
          if args.empty?
            on(*args, &block)
          else
            is(*args, &block)
          end
        end
      end

      module ResponseMethods
        CONTENT_LENGTH = "Content-Length".freeze
        CONTENT_TYPE = "Content-Type".freeze
        DEFAULT_CONTENT_TYPE = "text/html".freeze
        LOCATION = "Location".freeze

        attr_accessor :status

        attr_reader :headers

        def initialize
          @status  = nil
          @headers = default_headers
          @body    = []
          @length  = 0
        end

        def default_headers
          {CONTENT_TYPE => DEFAULT_CONTENT_TYPE}
        end

        def [](key)
          @headers[key]
        end

        def []=(key, value)
          @headers[key] = value
        end

        def write(str)
          s = str.to_s

          @length += s.bytesize
          @headers[CONTENT_LENGTH] = @length.to_s
          @body << s
          nil
        end

        def empty?
          @body.empty?
        end

        def redirect(path, status = 302)
          @headers[LOCATION] = path
          @status  = status
        end

        def finish
          b = @body
          s = (@status ||= b.empty? ? 404 : 200)
          [s, @headers, b]
        end

        def set_cookie(key, value)
          Rack::Utils.set_cookie_header!(@headers, key, value)
        end

        def delete_cookie(key, value = {})
          Rack::Utils.delete_cookie_header!(@headers, key, value)
        end
      end
    end
  end

  extend RodaPlugins::Base::ClassMethods
  plugin RodaPlugins::Base
end
