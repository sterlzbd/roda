# frozen-string-literal: true

#
class Roda
  module RodaPlugins
    # The status_303 plugin sets the default redirect status to be 303
    # rather than 302 when the request is not a GET and the
    # redirection occurs on an HTTP 1.1 connection as per RFC 7231.
    # There are some frontend frameworks that require this behavior.
    #
    # Example:
    #
    #   plugin :status_303
    module Status303
      module RequestMethods

        private

        def default_redirect_status
          if env['HTTP_VERSION'] == 'HTTP/1.1' && !is_get?
            303
          else
            super
          end
        end
      end
    end

    register_plugin(:status_303, Status303)
  end
end
