require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "hooks plugin" do 
  before do
    a = @a = []
    app(:bare) do
      plugin :hooks

      before do
        response['foo'] = 'bar'
      end

      after do |r|
        if r
          a << [r[0], r[1]['foo'], r[2]]
          r[0] += 1
        else
          a << r
        end
      end

      route do |r|
        r.is "" do
          f = response['foo']
          response['foo'] = 'baz'
          f
        end
      end
    end
  end

  it "adds before and after hooks for running code before and after requests" do
    s, h, b = req
    s.should == 201
    h['foo'].should == 'baz'
    b.join.should == 'bar'
    @a.should == [[200, 'baz', ['bar']]]
  end

  it "multiple plugin calls do not override existing hooks" do
    app.plugin :hooks
    s, h, b = req
    s.should == 201
    h['foo'].should == 'baz'
    b.join.should == 'bar'
    @a.should == [[200, 'baz', ['bar']]]
  end

  it "after hooks are still called if an exception is raised" do
    a = @a
    @app.before do
      raise Roda::RodaError, "foo"
    end

    @app.after do |r|
      a << r
      a << $!
    end

    proc{req}.should raise_error(Roda::RodaError)
    a.pop.should be_a_kind_of(Roda::RodaError)
    a.pop.should == nil
  end

  it "handles multiple before and after blocks correctly" do
    a = @a
    @app.before do
      response['bar'] = "foo#{response['foo']}"
    end

    @app.after do |r|
      a << r[1]['bar']
      r[0] *= 2
    end

    s, h, b = req
    s.should == 402
    h['foo'].should == 'baz'
    h['bar'].should == 'foo'
    b.join.should == 'bar'
    a.should == [[200, 'baz', ['bar']], 'foo']
  end

  it "copies before and after blocks when subclassing" do
    @app = Class.new(@app)
    @app.route do |r|
      r.on do
        "foo"
      end
    end
    s, h, b = req
    s.should == 201
    h['foo'].should == 'bar'
    b.join.should == 'foo'
    @a.should == [[200, 'bar', ['foo']]]
  end
end
