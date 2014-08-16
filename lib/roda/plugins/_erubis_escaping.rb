require 'erubis'

class Roda
  module RodaPlugins
    # The _erubis_escaping plugin is an internal plugin that provides a
    # subclass of Erubis::EscapedEruby with a bugfix and an optimization.
    module ErubisEscaping
      # Optimized subclass that fixes escaping of postfix conditionals.
      class Eruby < Erubis::EscapedEruby
        # Set escaping class to a local variable, so you don't need a
        # constant lookup per escape.
        def convert_input(codebuf, input)
          codebuf << '_erubis_xml_helper = Erubis::XmlHelper;'
          super
        end

        # Fix bug in Erubis::EscapedEruby where postfix conditionals inside
        # <%= %> are broken (e.g. <%= foo if bar %> ), and optimize by using
        # a local variable instead of a constant lookup.
        def add_expr_escaped(src, code)
          src << " #{@bufvar} << _erubis_xml_helper.escape_xml((" << code << '));'
        end
      end
    end

    register_plugin(:_erubis_escaping, ErubisEscaping)
  end
end
