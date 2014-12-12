class Roda
  module RodaPlugins
    # The empty_root plugin makes +r.root+ match both on +/+ and
    # on the empty string.  This is mostly useful when using multiple
    # rack applications, where the initial PATH_INFO has been moved
    # to SCRIPT_NAME.  For example, if you have the following
    # applications:
    #
    #   class App1 < Roda
    #     on "albums" do
    #       run App2
    #     end
    #   end
    #
    #   class App2 < Roda
    #     plugin :empty_root
    #
    #     route do |r|
    #       r.root do
    #         "root"
    #       end
    #     end
    #   end
    #
    # Then requests for both +/albums/+ and +/albums+ will return
    # "root".  Without this plugin loaded into App2, only requests
    # for +/albums/+ will return "root", since by default, +r.root+
    # matches only when the current PATH_INFO is +/+ and not when
    # it is empty.
    module EmptyRoot
      EMPTY_STRING = ''.freeze

      module RequestMethods
        # Match when the path to match is the empty string,
        # in addition to the default behavior of matching when
        # the path to match is +/+.
        def root(&block)
          super
          if path_to_match == EMPTY_STRING && is_get?
            always(&block)
          end
        end
      end
    end

    register_plugin(:empty_root, EmptyRoot)
  end
end
