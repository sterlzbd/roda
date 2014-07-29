class Roda
  module RodaPlugins
    # The header_matchers plugin adds hash matchers for matching on less-common
    # HTTP headers.
    #
    #   plugin :header_matchers
    #
    # It adds a +:header+ matcher for matching on arbitrary headers, which matches
    # if the header is present:
    #
    #   route do |r|
    #     r.on :header=>'X-App-Token' do
    #     end
    #   end
    #
    # It adds a +:host+ matcher for matching by the host of the request:
    #
    #   route do |r|
    #     r.on :host=>'foo.example.com' do
    #     end
    #   end
    #
    # It adds an +:accept+ matcher for matching based on the Accept header:
    #
    #   route do |r|
    #     r.on :accept=>'text/csv' do
    #     end
    #   end
    #
    # Note that the accept matcher is very simple and cannot handle wildcards,
    # priorities, or anything but a simple comma separated list of mime types.
    module HeaderMatchers
      module RequestMethods
        private

        # Match if the given mimetype is one of the accepted mimetypes.
        def match_accept(mimetype)
          if env["HTTP_ACCEPT"].to_s.split(',').any?{|s| s.strip == mimetype}
            response["Content-Type"] = mimetype
          end
        end

        # Match if the given uppercase key is present inside the environment.
        def match_header(key)
          env[key.upcase.tr("-","_")]
        end

        # Match if the host of the request is the same as the hostname.
        def match_host(hostname)
          hostname === host
        end
      end
    end

    register_plugin(:header_matchers, HeaderMatchers)
  end
end
