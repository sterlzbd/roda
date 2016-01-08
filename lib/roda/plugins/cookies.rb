# frozen-string-literal: true

class Roda
  module RodaPlugins
    # The cookies plugin adds response methods for handling cookies.
    # Currently, you can set cookies with +set_cookie+ and delete cookies
    # with +delete_cookie+:
    #
    #   response.set_cookie('foo', 'bar')
    #   response.delete_cookie('foo')
    module Cookies
      module ResponseMethods
        # Modify the headers to include a Set-Cookie value that
        # deletes the cookie.  A value hash can be provided to
        # override the default one used to delete the cookie.
        # Example:
        #
        #   response.delete_cookie('foo')
        #   response.delete_cookie('foo', :domain=>'example.org')
        def delete_cookie(key, value = {})
          ::Rack::Utils.delete_cookie_header!(@headers, key, value)
        end

        # Set the cookie with the given key in the headers.
        #
        #   response.set_cookie('foo', 'bar')
        #   response.set_cookie('foo', :value=>'bar', :domain=>'example.org')
        def set_cookie(key, value)
          ::Rack::Utils.set_cookie_header!(@headers, key, value)
        end
      end
    end

    register_plugin(:cookies, Cookies)
  end
end
