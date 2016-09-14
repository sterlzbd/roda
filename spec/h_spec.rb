require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "h" do
  it "escapes html entities" do
    app(:bare) do
      route do |r|
        r.on do
          h("<form>") + h(:form) + h("test&<>/'")
        end
      end
    end

    body.must_equal '&lt;form&gt;formtest&amp;&lt;&gt;/&#x27;'
  end
end
