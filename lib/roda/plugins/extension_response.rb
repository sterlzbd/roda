# frozen_string_literal: true

class Roda
  module RodaPlugins

    # Allows to respond to specific request data types. User agents can request
    # specific data types by either supplying an appropriate +Accept+ header
    # or by appending it as file extension to the path.
    #
    # Example:
    #
    #   route do |r|
    #     r.get 'a' do
    #       r.html{ "<h1>This is the HTML response</h1>" }
    #       r.json{ { json: "ok" } }
    #       r.xml{ "<root>This is the XML response</root>" }
    #       "Unsupported data type"
    #     end
    #   end
    #
    # The path +/a+ will respond either with HTML, JSON or XML data.
    # The matching block will automatically set the response +Content-Type+ to
    # a suitable value.
    #
    # Note that if no match is found, code will continue to execute, which can
    # yield to unexpected behaviour.
    #
    # To match custom extensions, make them known to the plugin through the
    # +:types+ option and use the +#extension+ method:
    #
    #   plugin :extension_response, :types => {
    #     :yaml => 'application/x-yaml',
    #     :js => 'application/javascript',
    #   }
    #
    #   route do |r|
    #     r.get 'a' do
    #       r.extension(:yaml){ YAML.dump "YAML data" }
    #       r.extension(:js){ "JavaScript code" }
    #       "Unsupported data type"
    #     end
    #   end
    #
    # = Plugin options
    #
    # The following plugin options are supported:
    #
    # :use_extension :: If to take the path extension into account. Default is
    #                   +true+.
    # :use_header :: If to take the +Accept+ header into account. Default is
    #                +true+.
    # :types :: Mapping from a data type to its MIME-Type. Used both to match
    #           incoming requests and to provide +Content-Type+ values.
    # :exclude :: Exclude one or more types from the default set.
    # :default :: The default data type to assume if the client did not provide
    #             one. Defaults to +:html+.
    module ExtensionResponse
      TYPES = %i[ html json xml ].freeze
      EXTENSION_RX = /\.([a-z]+)\z/.freeze
      ACCEPT_HEADER = 'HTTP_ACCEPT'.freeze
      CONTENT_TYPE_HEADER = 'Content-Type'.freeze
      DEFAULT_TYPE = :html
      EMPTY_OPTS = { }.freeze

      MIME_MAPPING = {
        'text/json' => :json,
        'application/json' => :json,
        'text/xml' => :xml,
        'application/xml' => :xml,
        'text/html' => :html,
      }.freeze

      RESPONSE_MAPPING = {
        :json => 'application/json',
        :xml => 'application/xml',
        :html => 'text/html',
      }.freeze

      def self.configure(app, opts = EMPTY_OPTS)
        config = {
          mimes: MIME_MAPPING,
          types: RESPONSE_MAPPING,
          use_extension: opts.fetch(:use_extension, true),
          use_header: opts.fetch(:use_header, true),
          default: opts.fetch(:default, DEFAULT_TYPE).to_sym,
        }

        if mapping = opts[:types]
          sym_map = mapping.map{|k, v| [ k.to_sym, v ]}.to_h
          config[:types] = RESPONSE_MAPPING.merge(sym_map).freeze
          config[:mimes] = MIME_MAPPING.merge(sym_map.invert).freeze
        end

        exclude = Array(opts[:exclude])
        unless exclude.empty?
          types = config[:types].dup
          mimes = config[:mimes].dup

          exclude.each do |type|
            types.reject!{|k, _| k == type}
            mimes.reject!{|_, v| v == type}
          end

          config[:types] = types.freeze
          config[:mimes] = mimes.freeze
        end

        type_rx = Regexp.union config[:types].keys.map(&:to_s)
        config[:ext_rx] = Regexp.new("\\.(#{type_rx.source})\\z").freeze
        app.opts[:extension_response] = config.freeze
      end

      module RequestMethods
        attr_reader :path_extension

        # Removes a trailing file extension from the path.
        def initialize(scope, env)
          super

          opts = scope.opts[:extension_response]
          return unless opts[:use_extension]
          if m = remaining_path.match(opts[:ext_rx])
            extension = m[1]
            @remaining_path = @remaining_path[0...-(extension.size + 1)]
            @path_extension = extension.to_sym
          end
        end

        # Yields if the given +type+ matches the requested data type and halts
        # the request afterwards, returning the result of the block.
        def extension(type)
          type = type.to_sym
          return unless type == requested_type

          opts = @scope.opts[:extension_response]
          if response[CONTENT_TYPE_HEADER].nil?
            response[CONTENT_TYPE_HEADER] = opts[:types][type]
          end

          block_result(yield)
          throw :halt, response.finish
        end

        TYPES.each do |type|
          define_method type do |&block|
            extension(type, &block)
          end
        end

        # Returns the data type the client requests.
        def requested_type
          opts = @scope.opts[:extension_response]
          header_type = accept_response_type if opts[:use_header]

          @path_extension || header_type || opts[:default]
        end

        private

        def accept_response_type
          opts = @scope.opts[:extension_response]
          header = parse_http_accept_header @env[ACCEPT_HEADER]
          header.each do |(mime, _)|
            sym = opts[:mimes][mime]
            return sym if sym
          end

          nil
        end
      end
    end

    register_plugin(:extension_response, ExtensionResponse)
  end
end
