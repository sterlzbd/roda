require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "params_capturing plugin" do 
  it "should add captures to r.params" do
    app(:params_capturing) do |r|
      r.on('foo/:y/:z', :w) do |y, z, w|
        (r.params.values_at('y', 'z', 'w') + [y, z, w]).join('-')
      end

      r.on("bar/:foo") do |foo|
        "b-#{foo}-#{r[:foo]}"
      end

      r.on(/(quux)/, :y) do |q, y|
        "y-#{r[:y]}-#{q}-#{y}"
      end

      r.on(:x) do |x|
        "x-#{x}-#{r[:x]}"
      end
    end

    body('/blarg', 'rack.input'=>StringIO.new).must_equal 'x-blarg-blarg'
    body('/foo/1/2/3', 'rack.input'=>StringIO.new).must_equal '1-2-3-1-2-3'
    body('/bar/banana', 'rack.input'=>StringIO.new).must_equal 'b-banana-banana'
    body('/quux/asdf', 'rack.input'=>StringIO.new).must_equal 'y--quux-asdf'
  end
end
