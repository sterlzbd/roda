require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "streaming plugin" do 
  it "adds stream method for streaming responses" do
    app(:streaming) do |r|
      stream do |out|
        %w'a b c'.each{|v| out << v}
      end
    end

    s, h, b = req
    s.should == 200
    h.should == {'Content-Type'=>'text/html'}
    b.to_a.should == %w'a b c'
  end

  it "should handle errors when streaming, and run callbacks" do
    app(:streaming) do |r|
      stream do |out|
        %w'a b'.each{|v| out << v}
        raise Roda::RodaError, 'foo'
        out << 'c'
      end
    end

    s, h, b = req
    s.should == 200
    h.should == {'Content-Type'=>'text/html'}
    a = []
    b.callback{a << 'd'}
    proc{b.each{|v| a << v}}.should raise_error(Roda::RodaError)
    a.should == %w'a b d'
  end
end
