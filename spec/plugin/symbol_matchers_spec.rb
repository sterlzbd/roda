require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "symbol_matchers plugin" do 
  it "allows usage of s" do
    app(:bare) do
      plugin :symbol_matchers
      symbol_matcher(:f, /(f+)/)

      route do |r|
        r.is :d do |d|
          "d#{d}"
        end

        r.is :f do |f|
          "f#{f}"
        end

        r.is :w do |w|
          "w#{w}"
        end

        r.is ':d/:w/:f' do |d, w, f|
          "dwf#{d}#{w}#{f}"
        end
      end
    end

    status.should == 404
    body("/1").should == 'd1'
    body("/11232135").should == 'd11232135'
    body("/a").should == 'wa'
    body("/1az0").should == 'w1az0'
    body("/f").should == 'ff'
    body("/ffffffffffffffff").should == 'fffffffffffffffff'
    status("/-").should == 404
    body("/1/1a/f").should == 'dwf11af'
    body("/12/1azy/fffff").should == 'dwf121azyfffff'
    status("/1/f/a").should == 404
  end
end
