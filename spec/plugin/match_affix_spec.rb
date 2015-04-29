require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "match_affix plugin" do 
  it "allows changing the match prefix/suffix" do
    app(:bare) do
      plugin :match_affix, "", /(\/|\z)/

      route do |r|
        r.on "/albums" do |b|
          r.on "b/:id" do |id, s|
            "b-#{b}-#{id}-#{s.inspect}"
          end

          "albums-#{b}"
        end
      end
    end

    body("/albums/a/1").must_equal 'albums-/'
    body("/albums/b/1").must_equal 'b-/-1-""'
  end
end
