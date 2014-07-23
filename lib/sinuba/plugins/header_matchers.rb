class Sinuba
  module SinubaPlugins
    module HeaderMatchers
      module RequestMethods
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
      end
    end
  end

  register_plugin(:header_matchers, SinubaPlugins::HeaderMatchers)
end
