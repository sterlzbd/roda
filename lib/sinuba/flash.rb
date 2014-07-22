require 'sinatra/flash/hash'

class Sinuba
  module Flash
    FlashHash = ::Sinatra::Flash::FlashHash

    module InstanceMethods
      KEY = :flash
      def flash
        @_flash ||= FlashHash.new((session ? session[KEY] : {}))
      end

      def call(env)
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
