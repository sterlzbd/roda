require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "optimized_string_matchers plugin" do 
  it "should support on_branch and is_exactly match methods" do
    app(:optimized_string_matchers) do |r|
      r.on_branch "e" do
        r.is_exactly "f" do
          "ef"
        end

        "ee"
      end

      r.on_branch "a/:b" do |*b|
        r.is_exactly ":c" do |*c|
          "c-#{c.length}"
        end

        "a-#{b.length}"
      end

      "cc"
    end

    body.must_equal 'cc'
    body('/a').must_equal 'cc'
    body('/a/').must_equal 'cc'
    body('/a/b/').must_equal 'a-0'
    body('/a/b/').must_equal 'a-0'
    body('/a/b/c').must_equal 'c-0'
    body('/a/b/c/').must_equal 'a-0'
    body('/a/b/c/d').must_equal 'a-0'
    body('/e').must_equal 'ee'
    body('/eb').must_equal 'cc'
    body('/e/').must_equal 'ee'
    body('/e/f').must_equal 'ef'
    body('/e/f/').must_equal 'ee'
    body('/e/fe').must_equal 'ee'
  end
end
