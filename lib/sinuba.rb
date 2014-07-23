require "rack"
require "thread"

class Sinuba
  SinubaVersion = '0.9.0'.freeze

  class SinubaError < StandardError; end

  class SinubaRequest < Rack::Request; end

  class SinubaResponse < Rack::Response; end

  @builder = Rack::Builder.new
  @middleware = []
  @plugins = {}
  @opts = {}

  module SinubaPlugins
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

        def inherited(child)
          super
          child.instance_variable_set(:@builder, Rack::Builder.new)
          child.instance_variable_set(:@middleware, @middleware.dup)
          child.instance_variable_set(:@opts, opts.dup)
          child.const_set(:SinubaRequest, Class.new(self::SinubaRequest))
          child.const_set(:SinubaResponse, Class.new(self::SinubaResponse))
        end

        def plugin(mixin, *args, &block)
          if mixin.is_a?(Symbol)
            mixin = load_plugin(mixin)
          end

          if defined?(mixin::InstanceMethods)
            include mixin::InstanceMethods
          end
          if defined?(mixin::ClassMethods)
            extend mixin::ClassMethods
          end
          if defined?(mixin::RequestMethods)
            self::SinubaRequest.send(:include, mixin::RequestMethods)
          end
          if defined?(mixin::ResponseMethods)
            self::SinubaResponse.send(:include, mixin::ResponseMethods)
          end
          
          if mixin.respond_to?(:configure)
            mixin.configure(self, *args, &block)
          end
        end

        def request(env)
          self::SinubaRequest.new(self::SinubaResponse.new, env)
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
          h = Sinuba.instance_variable_get(:@plugins)
          unless plugin = MUTEX.synchronize{h[name]}
            require "sinuba/plugins/#{name}"
            raise SinubaError, "Plugin #{name} did not register itself correctly in Sinuba::Plugins" unless plugin = MUTEX.synchronize{h[name]}
          end
          plugin
        end

        def register_plugin(name, mod)
          h = Sinuba.instance_variable_get(:@plugins)
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
          r = @_request = self.class.request(env)

          # This `catch` statement will either receive a
          # rack response tuple via a `halt`, or will
          # fall back to issuing a 404.
          #
          # When it `catch`es a throw, the return value
          # of this whole `call!` method will be the
          # rack response tuple, which is exactly what we want.
          catch(:halt) do
            instance_exec(r, &block)

            response.finish
          end
        end

        def session
          env["rack.session"] || raise(SinubaError, "You're missing a session handler. You can get started by adding use Rack::Session::Cookie")
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
            return unless args.all? { |arg| match(arg) }

            # The captures we yield here were generated and assembled
            # by evaluating each of the `arg`s above. Most of these
            # are carried out by #consume.
            body = yield(*captures)

            if body.is_a?(String)
              response.write(body)
            end

            halt response.finish
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
          matchdata = env[PATH_INFO].match(/\A\/(#{pattern})(\/|\z)/)

          return false unless matchdata

          path, *vars = matchdata.captures

          # Don't mutate SCRIPT_NAME, breaks try
          env[SCRIPT_NAME] += "/#{path}"
          env[PATH_INFO] = "#{vars.pop}#{matchdata.post_match}"

          captures.push(*vars)
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

        def match_header(key)
          env[key.upcase.tr("-","_")]
        end

        # Useful for matching against the request host (i.e. HTTP_HOST).
        #
        # @example
        #   on host("account1.example.com"), "api" do
        #     res.write "You have reached the API of account1."
        #   end
        def match_host(hostname)
          hostname === host
        end

        # If you want to match against the HTTP_ACCEPT value.
        #
        # @example
        #   # HTTP_ACCEPT=application/xml
        #   on accept("application/xml") do
        #     # automatically set to application/xml.
        #     res.write res["Content-Type"]
        #   end
        def match_accept(mimetype)
          if env["HTTP_ACCEPT"].to_s.split(',').any?{|s| s.strip == mimetype}
            response["Content-Type"] = mimetype
          end
        end

        def match_term(term)
          !(term ^ (env[PATH_INFO] == ""))
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
          on(get?, *args, &block)
        end
        def post(*args, &block)
          on(post?, *args, &block)
        end

        # If you want to halt the processing of an existing handler
        # and continue it via a different handler.
        #
        # @example
        #   def redirect(*args)
        #     run Sinuba.define{route{|r| r.on(true){r.redirect(*args)}}}.app
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
      end

      module ResponseMethods
        attr_accessor :status

        attr_reader :headers

        def initialize
          @status  = nil
          @headers = default_headers
          @body    = []
          @length  = 0
        end

        def default_headers
          {"Content-Type" => "text/html; charset=utf-8"}
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
          @headers["Content-Length"] = @length.to_s
          @body << s
          nil
        end

        def redirect(path, status = 302)
          @headers["Location"] = path
          @status  = status
        end

        def finish
          @status ||= if @body.empty?
            404
          else
            200
          end

          [@status, @headers, @body]
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

  extend SinubaPlugins::Base::ClassMethods
  plugin SinubaPlugins::Base
end
