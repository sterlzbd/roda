class Roda
  module RodaPlugins
    # The head plugin attempts to automatically handle HEAD requests,
    # by treating them as GET requests and returning an empty body
    # without modifying the response status or response headers.
    #
    # So for the following routes,
    #
    #   route do |r|
    #     r.root do
    #       'root'
    #     end
    #
    #     r.get 'a' do
    #       'a'
    #     end
    #
    #     r.is 'b', :method=>[:get, :post] do
    #       'b'
    #     end
    #   end
    #
    # HEAD requests for +/+, +/a+, and +/b+ will all return 200 status
    # with an empty body.
    module Head
      module InstanceMethods
        # Always use an empty response body for head requests, with a
        # content length of 0.
        def call(*)
          res = super
          if @_request.head?
            res[2] = []
          end
          res
        end
      end

      module RequestMethods
        # Consider HEAD requests as GET requests.
        def is_get?
          super || head?
        end

        private

        # If the current request is a HEAD request, match if one of
        # the given methods is a GET request.
        def match_method(method)
          super || (!method.is_a?(Array) && head? && method.to_s.upcase == 'GET')
        end
      end
    end

    register_plugin(:head, Head)
  end
end
