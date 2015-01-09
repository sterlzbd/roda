class Roda
  module RodaPlugins
    # The delete_nil_headers plugin deletes any headers whose
    # value is set to nil.  Because of how default headers are
    # set in Roda, if you have a default header but don't want
    # to set it for a specific request, you need to use this plugin
    # and set the value to nil so that 
    #
    # The following example will return "&lt;foo&gt;" as the body.
    #
    #   plugin :h
    #
    #   route do |r|
    #     h('<foo>')
    #   end
    module DeleteHeaders
      module ResponseMethods
        def finish
          res = super
          res[1].delete_if{|_, v| v.nil?}
          res
        end

        def finish_with_body(_)
          res = super
          res[1].delete_if{|_, v| v.nil?}
          res
        end
      end
    end

    register_plugin(:delete_headers, DeleteHeaders)
  end
end
