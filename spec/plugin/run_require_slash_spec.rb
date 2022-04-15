require_relative "../spec_helper"

describe "run_require_slash plugin" do 
  it "only dispatches to application " do
    sub = app do |r|
      "sub-#{r.remaining_path}"
    end

    app(:bare) do
      plugin :match_affix, "", /(\/|\z)/
      plugin :run_require_slash

      route do |r|
        r.on "/a" do |b|
          r.on "b" do |id, s|
            r.run sub
            "b-#{r.remaining_path}"
          end

          "albums-#{b}"
        end
      end
    end

    body("/a/b").must_equal 'sub-'
    body("/a/b/").must_equal 'sub-'
    body("/a/b//").must_equal 'sub-/'
    body("/a/b/1").must_equal 'b-1'
  end
end
