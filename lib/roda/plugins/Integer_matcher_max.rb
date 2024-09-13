# frozen-string-literal: true

#
class Roda
  module RodaPlugins
    # The Integer_matcher_max plugin sets the maximum integer value
    # value that the Integer class matcher will match by default.
    # By default, loading this plugin sets the maximum value to
    # 2**63-1, the largest signed 64-bit integer value:
    #
    #   plugin :Integer_matcher_max
    #   route do |r|
    #     r.is Integer do
    #       # Matches /9223372036854775807
    #       # Does not match /9223372036854775808
    #     end
    #   end
    #
    # To specify a different maximum value, you can pass a different
    # maximum value when loading the plugin:
    # 
    #   plugin :Integer_matcher_max, 2**64-1
    module IntegerMatcherMax
      def self.configure(app, max=nil)
        if max
          app::RodaRequest.class_eval do
            define_method(:_match_class_max_Integer){max}
            alias_method :_match_class_max_Integer, :_match_class_max_Integer
            private :_match_class_max_Integer
          end
        end
      end

      module RequestMethods
        private

        # Do not have the Integer matcher max when over the maximum
        # configured Integer value.
        def _match_class_convert_Integer(value)
          value = super
          value if value <= _match_class_max_Integer
        end

        # Use 2**63-1 as the default maximum value for the Integer
        # matcher.
        def _match_class_max_Integer
          9223372036854775807
        end
      end
    end

    register_plugin(:Integer_matcher_max, IntegerMatcherMax)
  end
end
