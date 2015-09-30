require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "default_status plugin" do
  it "sets the default response status to use for the response" do
    app(:bare) do
      plugin :default_status do
        201
      end
      route do |r|
        r.halt response.finish_with_body([])
      end
    end

    req[0].must_equal 201
  end

  it "should not override existing response" do
    app(:bare) do
      plugin :default_status do
        201
      end

      route do |r|
        response.status = 202
        r.halt response.finish_with_body([])
      end
    end

    req[0].must_equal 202
  end

  it "should work correctly in subclasses" do
    app(:bare) do
      plugin :default_status do
        201
      end

      route do |r|
        r.halt response.finish_with_body([])
      end
    end

    @app = Class.new(@app)

    req[0].must_equal 201
  end
end
