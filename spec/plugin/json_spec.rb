require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "json plugin" do
  before do
    c = Class.new do
      def to_json
        '[1]'
      end
    end

    app(:bare) do
      plugin :json, :classes=>[Array, Hash, c]

      route do |r|
        r.is 'array' do
          [1, 2, 3]
        end

        r.is "hash" do
          {'a'=>'b'}
        end

        r.is 'c' do
          c.new
        end
      end
    end
  end

  it "should use a json content type for a json response" do
    header('Content-Type', "/array").should == 'application/json'
    header('Content-Type', "/hash").should == 'application/json'
    header('Content-Type', "/c").should == 'application/json'
    header('Content-Type').should == 'text/html'
  end

  it "should convert objects to json" do
    body('/array').gsub(/\s/, '').should == '[1,2,3]'
    body('/hash').gsub(/\s/, '').should == '{"a":"b"}'
    body('/c').should == '[1]'
    body.should == ''
  end

  it "should work when subclassing" do
    @app = Class.new(app)
    app.route{[1]}
    body.should == '[1]'
  end

  it "should accept custom serializers" do
    app.plugin :json, :serializer => proc{|o| o.inspect}
    body("/hash").should == '{"a"=>"b"}'
  end
end
