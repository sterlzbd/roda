class Sinuba
  module SinubaPlugins
    module AllVerbs
      module RequestMethods
        %w'delete head options link patch put trace unlink'.each do |t|
          if Rack::Request.method_defined?("#{t}?")
            class_eval(<<-END, __FILE__, __LINE__+1)
              def #{t}(*args, &block)
                is_or_on(*args, &block) if #{t}?
              end
            END
          end
        end
      end
    end
  end

  register_plugin(:all_verbs, SinubaPlugins::AllVerbs)
end
