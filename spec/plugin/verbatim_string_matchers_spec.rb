require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "verbatim_string_matchers plugin" do 
  it "makes string matchers only match given strings exactly" do
    app(:verbatim_string_matchers) do |r|
      r.on "a" do
        "aa"
      end

      r.on ":b" do
        r.on "d" do
          "bd"
        end

        "bb"
      end

      r.on_prefix ":e" do
        r.is_exactly "f" do
          "ef"
        end

        "ee"
      end

      "cc"
    end

    body.must_equal 'cc'
    body('/a').must_equal 'aa'
    body('/a/').must_equal 'aa'
    body('/ab').must_equal 'cc'
    body('/:b').must_equal 'bb'
    body('/:b/').must_equal 'bb'
    body('/:b/d').must_equal 'bd'
    body('/:b/d/').must_equal 'bd'
    body('/:b/de').must_equal 'bb'
    body('/:e').must_equal 'ee'
    body('/:eb').must_equal 'cc'
    body('/:e/').must_equal 'ee'
    body('/:e/f').must_equal 'ef'
    body('/:e/f/').must_equal 'ee'
    body('/:e/fe').must_equal 'ee'
  end
end
