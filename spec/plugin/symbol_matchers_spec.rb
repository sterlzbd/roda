require_relative "../spec_helper"

describe "symbol_matchers plugin" do 
  it "allows symbol specific regexps for symbol matchers" do
    app(:bare) do
      plugin :symbol_matchers
      symbol_matcher(:f, /(f+)/)
      symbol_matcher(:c, /(c+)/) do |cs|
        [cs, cs.length] unless cs.length == 5
      end

      route do |r|
        r.is :d do |d|
          "d#{d}"
        end

        r.is "thing2", :thing do |d|
          "thing2#{d}"
        end

        r.is :f do |f|
          "f#{f}"
        end

        r.is :c do |cs, nc|
          "#{cs}#{nc}"
        end

        r.is 'q', :rest do |rest|
          "rest#{rest}"
        end

        r.is :w do |w|
          "w#{w}"
        end

        r.is :d, :w, :f, :c do |d, w, f, cs, nc|
          "dwfc#{d}#{w}#{f}#{cs}#{nc}"
        end
      end
    end

    status.must_equal 404
    body("/1").must_equal 'd1'
    body("/11232135").must_equal 'd11232135'
    body("/a").must_equal 'wa'
    body("/1az0").must_equal 'w1az0'
    body("/f").must_equal 'ff'
    body("/ffffffffffffffff").must_equal 'fffffffffffffffff'
    body("/c").must_equal 'c1'
    body("/cccc").must_equal 'cccc4'
    body("/ccccc").must_equal 'wccccc'
    status("/-").must_equal 404
    body("/1/1a/f/cc").must_equal 'dwfc11afcc2'
    body("/12/1azy/fffff/ccc").must_equal 'dwfc121azyfffffccc3'
    status("/1/f/a").must_equal 404
    body("/q/a/b/c/d//f/g").must_equal 'resta/b/c/d//f/g'
    body('/q/').must_equal 'rest'
    body('/thing2/q').must_equal 'thing2q'
  end
end
