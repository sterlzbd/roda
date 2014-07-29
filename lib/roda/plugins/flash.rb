require 'sinatra/flash/hash'

class Roda
  module RodaPlugins
    # The flash plugin adds a +flash+ instance method to Roda,
    # for typical web application flash handling, where values
    # set in the current flash hash are available in the next
    # request.
    #
    # With the example below, if a POST request is submitted,
    # it will redirect and the resulting GET request will
    # return 'b'.
    #
    #   plugin :flash
    #
    #   route do |r|
    #     r.is '' do
    #       r.get do
    #         flash['a']
    #       end
    #
    #       r.post do
    #         flash['a'] = 'b'
    #         r.redirect('')
    #       end
    #     end
    #   end
    #
    # The flash plugin uses sinatra-flash internally, so you
    # must install sinatra-flash in order to use it.
    module Flash
      FlashHash = ::Sinatra::Flash::FlashHash

      module InstanceMethods
        # The internal session key used to store the flash.
        KEY = :flash

        # Access the flash hash for the current request, loading
        # it from the session if it is not already loaded.
        def flash
          @_flash ||= FlashHash.new((session ? session[KEY] : {}))
        end

        private

        # If the routing doesn't raise an error, rotate the flash
        # hash in the session so the next request has access to it.
        def _route
          res = super

          if f = @_flash
            session[KEY] = f.next
          end

          res
        end
      end
    end

    register_plugin(:flash, Flash)
  end
end
