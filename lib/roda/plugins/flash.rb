require 'sinatra/flash/hash'

class Roda
  module RodaPlugins
    module Flash
      FlashHash = ::Sinatra::Flash::FlashHash

      module InstanceMethods
        KEY = :flash
        def flash
          @_flash ||= FlashHash.new((session ? session[KEY] : {}))
        end

        private

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
