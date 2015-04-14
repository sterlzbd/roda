require 'json'

class Roda
  module RodaPlugins
    # The json_parser plugin parses request bodies in json format
    # if the request's content type specifies json. This is mostly
    # designed for use with JSON API sites.
    #
    # This only parses the request body as JSON if the Content-Type
    # header for the request includes "json".
    module JsonParser
      OPTS = {}.freeze
      JSON_PARAMS_KEY = "roda.json_params".freeze
      INPUT_KEY = "rack.input".freeze
      FORM_HASH_KEY = "rack.request.form_hash".freeze
      FORM_INPUT_KEY = "rack.request.form_input".freeze
      DEFAULT_ERROR_HANDLER = proc{|r| r.halt [400, {}, []]}

      # Handle options for the json_parser plugin:
      # :error_handler :: A proc to call if an exception is raised when
      #                   parsing a JSON request body.  The proc is called
      #                   with the request object, and should probably call
      #                   halt on the request or raise an exception.
      def self.configure(app, opts=OPTS)
        app.opts[:json_parser_error_handler] = opts[:error_handler] || app.opts[:json_parser_error_handler] || DEFAULT_ERROR_HANDLER
      end

      module RequestMethods
        # If the Content-Type header in the request includes "json",
        # parse the request body as JSON.  Ignore an empty request body.
        def POST
          env = @env
          if post_params = (env[JSON_PARAMS_KEY] || env[FORM_HASH_KEY])
            post_params
          elsif (input = env[INPUT_KEY]) && content_type =~ /json/
            str = input.read
            input.rewind
            return super if str.empty?
            begin
              json_params = env[JSON_PARAMS_KEY] = parse_json(str)
            rescue
              roda_class.opts[:json_parser_error_handler].call(self)
            end
            env[FORM_INPUT_KEY] = input
            json_params
          else
            super
          end
        end

        private

        # Parses the given string as JSON.  Uses JSON.parse by default,
        # but can be overridden to use a different implementation.
        def parse_json(str)
          JSON.parse(str)
        end
      end
    end

    register_plugin(:json_parser, JsonParser)
  end
end
