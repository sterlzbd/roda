require_relative "../spec_helper"

describe "match hook plugin" do
  it "matches verbs" do
    matches = []
    app(:bare) do
      plugin :match_hook
      match_hook do
        matches.push request.matched_path
      end
      route do |r|
        r.get "foo" do
          "true"
        end

        r.post "bar" do
          "true"
        end
      end
    end

    req("/foo")
    matches.must_equal ["/foo"]

    matches.clear

    req("/bar", { "REQUEST_METHOD" => "POST" })
    matches.must_equal ["/bar"]
  end

  it "matches on deep nesting" do
    matches = []
    app(:bare) do
      plugin :match_hook
      match_hook do
        matches.push request.matched_path
      end
      route do |r|
        r.on "foo" do
          r.on "bar" do
            r.get "baz" do
              "foo/bar/baz"
            end
          end

          r.get "baz" do
            "baz"
          end
        end
      end
    end

    req("/foo/bar/baz")
    matches.must_equal ["/foo", "/foo/bar", "/foo/bar/baz"]
  end
end
