require_relative "../spec_helper"

describe "match hook plugin" do
  before do
    hooks = 0

    app(:bare) do
      plugin :match_hook

      match_hook do
        hooks += 1
      end

      route do |r|
        r.get "foo" do
          hooks.to_s
        end
      end
    end
  end

  it "calls match_hook on a successful match" do
    body("/foo").must_equal "1"
  end
end
