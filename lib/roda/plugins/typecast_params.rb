# frozen-string-literal: true

require 'date'
require 'time'

class Roda
  module RodaPlugins
    # The typecast_params plugin allows for the simple type conversion for
    # submitted parameters.  Submitted parameters should be considered
    # untrusted input, and in standard use with browsers, parameters are
    # submitted as strings (or a hash/array containing strings).  In most
    # cases it makes sense to explicitly convert the parameter to the
    # desired type.  While this can be done via manual conversion:
    #
    #   key = request.params['key'].to_i
    #
    # the typecast_params plugin adds a slightly friendly interface:
    #
    #   key = typecast_params.int('key')
    #
    # One advantage of using typecast_params is that access or conversion
    # errors are raised as a specific exception class
    # (+Roda::RodaPlugins::TypecastParams::Error+).  This allows you to handle
    # this specific exception class globally and return an appropriate 4xx
    # response to the client.
    #
    # typecast_params offers support for default values:
    #
    #   key = typecast_params.int('key', 1)
    #
    # The default value is only used if no value has been submitted for the parameter,
    # or if the conversion of the value results in +nil+.  Handling defaults for parameter
    # conversion manually is more difficult, since the parameter may not be present at all,
    # or it may be present but an empty string because the user did not enter a value on
    # the related form.  Use of typecast_params for the conversion handles both cases.
    #
    # In many cases, parameters should be required, and if they aren't submitted, that
    # should be considered an error.  typecast_params handles this with ! methods:
    #
    #   key = typecast_params.int!('key')
    #
    # These ! methods raise an error instead of returning +nil+, and do not allow defaults.
    #
    # To make it easy to handle cases where many parameters need the same conversion
    # done, you can pass an array of keys to a conversion method, and it will return an array
    # of converted values:
    #
    #   key1, key2 = typecast_params.int(['key1', 'key2'])
    #
    # This is equivalent to:
    #
    #   key1 = typecast_params.int('key1')
    #   key2 = typecast_params.int('key2')
    #
    # The ! methods also support arrays, ensuring that all parameters have a value:
    #
    #   key1, key2 = typecast_params.int!(['key1', 'key2'])
    #
    # For handling of array parameters, where all entries in the array use the
    # same conversion, there is an +array+ method which takes the type as the first argument
    # and the keys to convert as the second argument:
    #
    #   keys = typecast_params.array(:int, 'keys')
    #
    # If you want to ensure that all entries in the array are converted successfully and that
    # there is a value for the array itself, you can use +array!+:
    #
    #   keys = typecast_params.array!(:int, 'keys')
    #
    # This will raise an exception if any of the values in the array for parameter +keys+ cannot
    # be converted to integer.
    #
    # Both +array+ and +array!+ support default values which are used if no value is present
    # for the parameter:
    #
    #   keys = typecast_params.array(:int, 'keys', [])
    #   keys = typecast_params.array!(:int, 'keys', [])
    #
    # You can also pass an array of keys to +array+ or +array!+, if you would like to perform
    # the same conversion on multiple arrays:
    #
    #   key1, key2 = typecast_params.array!(:int, ['key1', 'key2'])
    #
    # The previous examples have shown use of the +int+ method, which uses +to_i+ to convert the
    # value to an integer.  There are many other built in methods for type conversion:
    #
    # any :: Returns the value as is without conversion
    # str :: Raises if value is not already a string
    # nonempty_str :: Raises if value is not already a string, strips the string, and converts
    #                 the empty string to +nil+
    # bool :: Converts entry to boolean if in one of the recognized formats:
    #         nil :: nil, ''
    #         true :: true, 1, '1', 't', 'true', 'yes', 'y', 'on' # case insensitive
    #         false :: false, 0, '0', 'f', 'false', 'no', 'n', 'off' # case insensitive
    #         If not in one of those formats, raises an error.
    # int :: Converts value to integer using +to_i+
    # pos_int :: Converts value using +to_i+, but non-positive values are converted to +nil+
    # Integer :: Converts value to integer using <tt>Kernel::Integer(value, 10)</tt>
    # float :: Converts value to float using +to_f+
    # Float :: Converts value to float using <tt>Kernel::Float(value)</tt>
    # Hash :: Raises if value is not already a hash
    # date :: Converts value to Date using <tt>Date.parse(value)</tt>
    # time :: Converts value to Time using <tt>Time.parse(value)</tt>
    # datetime :: Converts value to DateTime using <tt>DateTime.parse(value)</tt>
    # file :: Raises if value is not already a hash with a :tempfile key whose value
    #         responds to +read+ (this is the format rack uses for uploaded files).
    #
    # All of these methods also support ! methods (e.g. +pos_int!+), and all of them can be
    # used in the +array+ and +array!+ methods to support arrays of values.
    #
    # Since parameter hashes can be nested, the <tt>[]</tt> method can be used to access nested
    # hashes:
    #
    #   # params: {'key'=>{'sub_key'=>'1'}}
    #   typecast_params['key'].int!('sub_key') # => 1
    #
    # This works to an arbitrary depth:
    #
    #   # params: {'key'=>{'sub_key'=>{'sub_sub_key'=>'1'}}}
    #   typecast_params['key']['sub_key'].int!('sub_sub_key') # => 1
    #
    # And also works with arrays at any depth, if those arrays contain hashes:
    #
    #   # params: {'key'=>[{'sub_key'=>{'sub_sub_key'=>'1'}}]}
    #   typecast_params['key'][0]['sub_key'].int!('sub_sub_key') # => 1
    #
    #   # params: {'key'=>[{'sub_key'=>['1']}]}
    #   typecast_params['key'][0].array!(:int, 'sub_key') # => [1]
    #
    # To allow easier access to nested data, there is a +dig+ method:
    #
    #   typecast_params.dig(:int, 'key', 'sub_key')
    #   typecast_params.dig(:int!, 'key', 0, 'sub_key', 'sub_sub_key')
    #
    # +dig+ will return +nil+ if any access while looking up the nested value returns +nil+.
    # There is also a +dig!+ method, which will raise an Error if +dig+ would return +nil+:
    #
    #   typecast_params.dig!(:int, 'key', 'sub_key')
    #   typecast_params.dig!(:int, 'key', 0, 'sub_key', 'sub_sub_key')
    #
    # Note that none of these conversion methods modify +request.params+.  They purely do the
    # conversion and return the converted value.  However, in some cases it is useful to do all
    # the conversion up front, and then pass a hash of converted parameters to an internal
    # method that expects to receive values in specific types.  The +convert!+ method does
    # this, and there is also a +convert_each!+ method
    # designed for converting multiple values using the same block:
    #
    #   converted_params = typecast_params.convert! do |tp|
    #     tp.int('page')
    #     tp.pos_int!('artist_id')
    #     tp.array!(:pos_int, 'album_ids')
    #     tp['sales'].convert! do |stp|
    #       tp.int!(['num_sold', 'num_shipped'])
    #     end
    #     tp['members'].convert_each! do |stp|
    #       stp.str!(['first_name', 'last_name'])
    #     end
    #   end
    #
    #   # converted_params:
    #   # {
    #   #   'page' => 1,
    #   #   'artist_id' => 2,
    #   #   'album_ids' => [3, 4],
    #   #   'sales' => {
    #   #     'num_sold' => 5,
    #   #     'num_shipped' => 6
    #   #   },
    #   #   'members' => [
    #   #      {'first_name' => 'Foo', 'last_name' => 'Bar'},
    #   #      {'first_name' => 'Baz', 'last_name' => 'Quux'}
    #   #   ]
    #   # }
    #
    # +convert!+ and +convert_each!+ only return values you explicitly specify for conversion
    # inside the passed block.
    # 
    # You can specify the +:symbolize+ option to +convert!+ or +convert_each!+, which will
    # symbolize the resulting hash keys:
    #
    #   converted_params = typecast_params.convert!(symbolize: true) do |tp|
    #     tp.int('page')
    #     tp.pos_int!('artist_id')
    #     tp.array!(:pos_int, 'album_ids')
    #     tp['sales'].convert! do |stp|
    #       tp.int!(['num_sold', 'num_shipped'])
    #     end
    #     tp['members'].convert_each! do |stp|
    #       stp.str!(['first_name', 'last_name'])
    #     end
    #   end
    #
    #   # converted_params:
    #   # {
    #   #   :page => 1,
    #   #   :artist_id => 2,
    #   #   :album_ids => [3, 4],
    #   #   :sales => {
    #   #     :num_sold => 5,
    #   #     :num_shipped => 6
    #   #   },
    #   #   :members => [
    #   #      {:first_name => 'Foo', :last_name => 'Bar'},
    #   #      {:first_name => 'Baz', :last_name => 'Quux'}
    #   #   ]
    #   # }
    #
    # Using the +:symbolize+ option makes it simpler to transition from untrusted external
    # data (string keys), to trusted data that can be used internally (trusted in the sense that
    # the expected types are used).
    #
    # When loading the typecast_params plugin, a subclass of +TypecastParams::Params+ is created
    # specific to the Roda application.  You can add support for custom types by passing a block
    # when loading the typecast_params plugin.  This block is executed in the context of the
    # subclass, and calling +handle_type+ in the block can be used to add conversion methods:
    #
    #   plugin :typecast_params do
    #     handle_type(:decimal) do |value|
    #       case value
    #       when ''
    #         nil
    #       when String, Integer
    #         BigDecimal.new(value)
    #       when Float
    #         BigDecimal.new(value, 15)
    #       else
    #         raise ArgumentError, "invalid value for decimal: #{value.inspect}"
    #       end
    #     end
    #   end
    #
    # By design, typecast_params only deals with string keys, it is not possible to use
    # symbol keys as arguments to the conversion methods and have them converted.
    module TypecastParams
      # Exception class for errors that are caused by misuse of the API by the programmer.
      # These are different from +Error+ which are raised because the submitted parameters
      # do not match what is expected.  Should probably be treated as a 5xx error.
      class ProgrammerError < RodaError; end

      # Exception class for errors that are due to the submitted parameters not matching
      # what is expected.  Should probably be treated as a 4xx error.
      class Error < RodaError
        # Create a new instance with the keys and message set, and optionally using
        # the given backtrace.
        def self.create(keys, message, backtrace=nil)
          e = new(message)
          e.keys = keys
          e.set_backtrace(backtrace) if backtrace
          e
        end

        # Set the keys in the given exception.  If the exception is not already an
        # instance of the class, create a new instance to wrap it.
        def self.set_keys(keys, e)
          if e.is_a?(self)
            e.keys = keys
            e
          else
            create(keys, "#{e.class}: #{e.message}", e.backtrace)
          end
        end

        # The keys used to access the parameter that caused the error.  This is an array
        # that can be splatted to +dig+ to get the value of the parameter causing the error.
        attr_accessor :keys

        # The likely parameter name where the contents were not expected.  This is
        # designed for cases where the parameter was submitted with the typical
        # application/x-www-form-urlencoded or multipart/form-data content types,
        # and assumes the typical rack parsing of these content types into
        # parameters.  # If the parameters were submitted via JSON, #keys should be
        # used directly.
        # 
        # Example:
        # 
        #   # keys: ['page']
        #   param_name => 'page'
        # 
        #   # keys: ['artist', 'name']
        #   param_name => 'artist[name]'
        # 
        #   # keys: ['album', 'artist', 'name']
        #   param_name => 'album[artist][name]'
        def param_name
          if keys.length > 1
            first, *rest = keys
            v = first.dup
            rest.each do |param|
              v << "["
              v << param unless param.is_a?(Integer)
              v << "]"
            end
            v
          else
            keys.first
          end
        end
      end

      # Class handling conversion of submitted parameters to desired types.
      class Params
        # Handle conversions for the given type using the given block.
        # For a type named +foo+, this will create the following methods:
        #
        # * foo(key, default=nil)
        # * foo!(key)
        # * convert_foo(value) # private
        # * convert_array_foo(value) # private
        #
        # This method is used to define all type conversions, even the built
        # in ones.  It can be called in subclasses to setup subclass-specific
        # types.
        def self.handle_type(type, &block)
          convert_meth = :"convert_#{type}"
          define_method(convert_meth, &block)

          convert_array_meth = :"_convert_array_#{type}"
          define_method(convert_array_meth) do |v|
            raise Error, "expected array but received #{v.inspect}" unless v.is_a?(Array)
            v.map!{|val| send(convert_meth, val)}
          end

          private convert_meth, convert_array_meth

          define_method(type) do |key, default=nil|
            process_arg(convert_meth, key, default)
          end

          define_method(:"#{type}!") do |key|
            check_value!(key, send(type, key))
          end
        end

        # Create a new instance with the given object and nesting level.
        # +obj+ should be an array or hash, and +nesting+ should be an
        # array.  Designed for internal use, should not be called by
        # external code.
        def self.nest(obj, nesting)
          v = allocate
          v.instance_variable_set(:@nesting, nesting)
          v.send(:initialize, obj)
          v
        end

        handle_type(:any) do |v|
          v
        end

        handle_type(:str) do |v|
          raise Error, "expected string but received #{v.inspect}" unless v.is_a?(::String)
          v
        end

        handle_type(:nonempty_str) do |v|
          if (v = convert_str(v)) && !v.strip.empty?
            v
          end
        end

        handle_type(:bool) do |v|
          case v
          when ''
            nil
          when false, 0, /\A(?:0|f(?:alse)?|no?|off)\z/i
            false
          when true, 1, /\A(?:1|t(?:rue)?|y(?:es)?|on)\z/i
            true
          else
            raise Error, "expected bool but received #{v.inspect}"
          end
        end

        handle_type(:int) do |v|
          string_or_numeric!(v) && v.to_i
        end

        handle_type(:pos_int) do |v|
          if (v = convert_int(v)) && v > 0
            v
          end
        end

        handle_type(:Integer) do |v|
          string_or_numeric!(v) && ::Kernel::Integer(v, 10)
        end

        handle_type(:float) do |v|
          string_or_numeric!(v) && v.to_f
        end

        handle_type(:Float) do |v|
          string_or_numeric!(v) && ::Kernel::Float(v)
        end

        handle_type(:Hash) do |v|
          raise Error, "expected hash but received #{v.inspect}" unless v.is_a?(::Hash)
          v
        end

        handle_type(:date) do |v|
          parse!(::Date, v)
        end

        handle_type(:time) do |v|
          parse!(::Time, v)
        end

        handle_type(:datetime) do |v|
          parse!(::DateTime, v)
        end

        handle_type(:file) do |v|
          raise Error, "expected hash with :tempfile entry" unless v.is_a?(::Hash) && v.has_key?(:tempfile) && v[:tempfile].respond_to?(:read)
          v
        end

        # The current nesting level, showing where the current parameter object is in the
        # parameter hierarchy.
        attr_reader :nesting

        # Set the object used for converting.  Conversion methods will convert members of
        # the passed object.
        def initialize(obj)
          case @obj = obj
          when Hash, Array
            # nothing
          else
            if @nesting
              raise Error.create(keys(nil), "value of #{param_name(nil)} parameter not an array or hash: #{obj.inspect}")
            else
              raise Error.create(keys(nil), "parameters given not an array or hash: #{obj.inspect}")
            end
          end
        end

        # If key is a String Return whether the key is present in the object,
        def present?(key)
          case key
          when String
            !any(key).nil?
          when Array
            key.all? do |k|
              raise ProgrammerError, "non-String element in array argument passed to present?: #{k.inspect}" unless k.is_a?(String)
              !any(k).nil?
            end
          else
            raise ProgrammerError, "unexpected argument passed to present?: #{key.inspect}"
          end
        end

        # Return a new Params instance for the given +key+. The value of +key+ should be an array
        # if +key+ is an integer, or hash otherwise.
        def [](key)
          @subs ||= {}
          if sub = @subs[key]
            return sub
          end

          if @obj.is_a?(Array)
            raise Error.create(keys(nil), "invalid use of non-integer key for accessing array: #{key.inspect}") unless key.is_a?(Integer)
          else
            raise Error.create(keys(nil), "invalid use of integer key for accessing hash: #{key}") if key.is_a?(Integer)
          end

          v = @obj[key]
          v = yield if v.nil? && block_given?

          sub = @subs[key] = self.class.nest(v, Array(@nesting) + [key])
          sub.start_capture(:symbolize=>@capture == :symbolize) if @capture
          sub
        end
        
        # Return the nested value for key. If there is no nested_value for +key+,
        # calls the block to return the value, or returns nil if there is no block given.
        def fetch(key)
          send(:[], key){return(yield if block_given?)}
        end

        # Captures conversions inside the given block, and returns a hash of all conversions,
        # including conversions of subkeys.  Options:
        #
        # :symbolize :: Convert any string keys in the resulting hash and for any
        #               conversions below
        def convert!(opts=OPTS)
          capturing_started = start_capture(opts)

          yield self

          nested_params
        ensure
          # Only unset capturing if capturing was not already started.
          @capture = false if capturing_started
        end

        # Runs convert! for each key specified by the :keys option.  If no :keys option is given and the object is an array,
        # runs convert! for all entries in the array.
        # Raises an Error if the current object is not an array and :keys option is not specified.
        # Passes any options given to #convert!.  Options:
        #
        # :keys :: The keys to extract from the object
        def convert_each!(opts=OPTS, &block)
          unless keys = opts[:keys]
            raise Error.create(keys(nil), "convert_each! called on non-array") unless @obj.is_a?(Array)
            keys = (0...@obj.length)
          end

          keys.map do |i|
            self[i].convert!(opts, &block)
          end
        end

        # Return nested values under the current obj, calling +type+ with +key+ on the nested object (traversed
        # to using +nest+).  Example:
        #
        #   tp.dig(:int, 'foo')               # tp.int('foo')
        #   tp.dig(:int, 'foo', 'bar')        # tp['foo'].int('bar')
        #   tp.dig(:int, 'foo', 'bar', 'baz') # tp['foo']['bar'].int('baz')
        #
        # Returns nil if any of the values are not present or not the expected type. If the nest path results
        # in an object that is not an array or hash, then raises an Error.
        #
        # It is possible to use +:[]+ as the +type+, in which case this will return a nested value that
        # other methods can be called on:
        #
        #   tp.dig(:[], 'foo', 'bar')        # tp['foo']['bar']
        # 
        # You can use +dig+ to get access to nested arrays:
        #
        #   tp.dig([:array, :int], 'foo', 'bar', 'baz')  # tp['foo']['bar'].array(:int, 'baz')
        def dig(type, *nest, key)
          if type.is_a?(Array)
            meth = type.first
          else
            meth = type
            type = [type]
          end

          raise ProgrammerError, "no typecast_params type registered for #{meth.inspect}" unless respond_to?(meth)
          cur = self

          nest.each do |k|
            case k
            when String
              return unless cur.obj.is_a?(Hash)
              cur = cur.fetch(k){return}
            when Integer
              return unless cur.obj.is_a?(Array)
              cur = cur.fetch(k){return}
            else
              raise ProgrammerError, "invalid argument passed to dig: #{k}"
            end
          end

          cur.send(*type, key)
        end

        # Similar to +dig+, but raises an Error instead of returning +nil+ if no value is found.
        def dig!(type, *nest, key)
          check_value!(key, dig(type, *nest, key), Array(nesting)+nest)
        end

        # Convert the value of +key+ to an array of values of the given +type+. If +default+ is
        # given, any +nil+ values in the array are replaced with +default+.  If +key+ is an array
        # then this returns an array of arrays, one for each respective value of +key+. If there is
        # no value for +key+, nil is returned instead of an array.
        def array(type, key, default=nil)
          meth = :"_convert_array_#{type}"
          raise ProgrammerError, "no typecast_params type registered for #{type.inspect}" unless respond_to?(meth, true)
          process_arg(meth, key, default)
        end

        # Call +array+ with the +type+, +key+, and +default+, but if the return value is nil or any value in
        # the returned array is +nil+, raise an Error.
        def array!(type, key, default=nil)
          v = check_value!(key, array(type, key, default))

          if key.is_a?(Array)
            key.zip(v).each do |key, arr|
              raise Error.create(keys(key), "invalid value in array parameter #{param_name(key)}") if arr.any?{|val| val.nil?}
            end
          else
            raise Error.create(keys(key), "invalid value in array parameter #{param_name(key)}") if v.any?{|val| val.nil?}
          end

          v
        end

        protected

        # The object being wrapped.
        attr_reader :obj

        # Start capturing data for this object.  Returns whether this call started the
        # capturing.
        def start_capture(opts)
          capturing_started = unless @capture
            @capture = true
            @params = @obj.class.new
            @subs.clear if @subs
            true
          end

          if opts.has_key?(:symbolize)
            @capture = opts[:symbolize] ? :symbolize : true
          end

          capturing_started
        end

        # Recursively descendent into all known subkeys and get the converted params from each.
        def nested_params
          params = @params ||= @obj.class.new

          if @subs
            @subs.each do |key, v|
              if key.is_a?(String) && @capture == :symbolize
                key = key.to_sym
              end
              params[key] = v.nested_params
            end
          end
          
          params
        end

        private

        # If +key+ is an array, then raise an Error if any value of of the array is +nil+.
        # Otherwise, raise an Error if +v+ is nil.
        def check_value!(key, v, nest=nesting)
          if key.is_a?(Array)
            if v.any?(&:nil?)
              keys = key.zip(v).reject{|_, val| val.nil?}.map(&:first)
              raise Error.create(Array(nest) + [keys.first], "missing parameters for #{keys.map{|k| param_name(k)}.join(', ')}")
            end
          elsif v.nil?
            raise Error.create(Array(nest) + Array(key), "missing parameter for #{param_name(key)}")
          end

          v
        end

        # Format a reasonable parameter name value, for use in exception messages.
        def param_name(key)
          keys = Array(nesting) + Array(key)
          first, *rest = keys
          v = first.dup
          rest.each do |param|
            v << "[#{param}]"
          end
          v
        end

        # If +key+ is not +nil+, add it to the given nesting.  Otherwise, just return the given nesting.
        # Designed for use in setting the +keys+ values in raised exceptions.
        def keys(key)
          Array(nesting) + Array(key)
        end

        # Handle any conversion errors.  By default, reraises Error instances with the keys set,
        # converts ::ArgumentError instances to Error instances, and reraises other exceptions.
        # Can be overridden in subclasses to record all errors.
        def handle_error(key, e)
          case e
          when Error, ArgumentError
            raise Error.set_keys(keys(key), e)
          else
            raise e
          end
        end

        # If +key+ is not an array, convert the value at the given +key+ using the +meth+ method, and if
        # the value is nil, return +default+ instead of the value.
        # If +key+ is an array, return an array with the conversion done for each respective member of +key+.
        def process_arg(meth, key, default)
          case key
          when String
            v = process(meth, key)
            v = default if v.nil?
            if cap = @capture
              key = key.to_sym if cap == :symbolize
              @params[key] = v
            end
            v
          when Array
            key.map do |k|
              raise ProgrammerError, "non-String element in array argument passed to typecast_params: #{k.inspect}" unless k.is_a?(String)
              process_arg(meth, k, default)
            end
          else
            raise ProgrammerError, "Unsupported argument for typecast_params conversion method: #{key.inspect}"
          end
        end

        # Get the value of +key+ for the object, and convert it to the expected type using +meth+.
        def process(meth, key)
          v = @obj[key]
          unless v.nil?
            send(meth, v)
          end
        rescue => e
          handle_error(key, e)
        end

        # Helper for conversion methods where '' should be considered nil,
        # and only String or Numeric values should be converted.
        def string_or_numeric!(v)
          case v
          when ''
            nil
          when String, Numeric
            true
          else
            raise Error, "unexpected value received: #{v.inspect}"
          end
        end

        # Helper for conversion methods where '' should be considered nil,
        # and only String values should be converted by calling +parse+ on
        # the given +klass+.
        def parse!(klass, v)
          case v
          when ''
            nil
          when String
            klass.parse(v)
          else
            raise Error, "unexpected value received: #{v.inspect}"
          end
        end
      end

      # Set application-specific Params subclass unless one has been set,
      # and if a block is passed, eval it in the context of the subclass.
      def self.load_dependencies(app, &block)
        app.const_set(:TypecastParams, Class.new(RodaPlugins::TypecastParams::Params)) unless app.const_defined?(:TypecastParams)
        app::TypecastParams.class_eval(&block) if block
      end

      module ClassMethods
        # Freeze the Params subclass when freezing the class.
        def freeze
          self::TypecastParams.freeze
          super
        end

        # Assign the application subclass a subclass of the current Params subclass.
        def inherited(subclass)
          super
          subclass.const_set(:TypecastParams, Class.new(self::TypecastParams))
        end
      end

      module InstanceMethods
        # Return and cache the instance of the Params class for the current request.
        # Type conversion methods will be called on the result of this method.
        def typecast_params
          @_typecast_params ||= self.class::TypecastParams.new(@_request.params)
        end
      end
    end

    register_plugin(:typecast_params, TypecastParams)
  end
end
