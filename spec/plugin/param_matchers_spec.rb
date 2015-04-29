require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "param_matchers plugin" do 
  it "param! matcher should yield a param only if given and not empty" do
    app(:param_matchers) do |r|
      r.get "signup", :param! => "email" do |email|
        email
      end

      r.on do
        "No email"
      end
    end

    io = StringIO.new
    body("/signup", "rack.input" => io, "QUERY_STRING" => "email=john@doe.com").must_equal 'john@doe.com'
    body("/signup", "rack.input" => io, "QUERY_STRING" => "").must_equal 'No email'
    body("/signup", "rack.input" => io, "QUERY_STRING" => "email=").must_equal 'No email'
  end

  it "param matcheshould yield a param only if given" do
    app(:param_matchers) do |r|
      r.get "signup", :param=>"email" do |email|
        email
      end

      r.on do
        "No email"
      end
    end

    io = StringIO.new
    body("/signup", "rack.input" => io, "QUERY_STRING" => "email=john@doe.com").must_equal 'john@doe.com'
    body("/signup", "rack.input" => io, "QUERY_STRING" => "").must_equal 'No email'
    body("/signup", "rack.input" => io, "QUERY_STRING" => "email=").must_equal ''
  end
end
