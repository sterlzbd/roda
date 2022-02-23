require_relative "spec_helper"

describe "session handling" do
  include CookieJar

  it "should give a warning if session variable is not available" do
    app do |r|
      begin
        session
      rescue Exception => e
        e.message
      end
    end

    body.must_match("You're missing a session handler, try using the sessions plugin.")
  end

  it "should return session if session middleware is used" do
    require 'roda/session_middleware'
    app(:bare) do
      if RUBY_VERSION >= '2.0'
        require 'roda/session_middleware'
        use RodaSessionMiddleware, :secret=>'1'*64
      else
        use Rack::Session::Cookie, :secret=>'1'*64
      end

      route do |r|
        r.on do
          (session[1] ||= 'a'.dup) << 'b'
          session[1]
        end
      end
    end

    _, _, b = req
    b.join.must_equal 'ab'
    _, _, b = req
    b.join.must_equal 'abb'
    _, _, b = req
    b.join.must_equal 'abbb'
  end
end
