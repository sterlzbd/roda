require_relative "../spec_helper"

describe "yield_response plugin" do
  describe "configured in fast mode" do
    it "yields #response as a second route block argument" do
      app(:bare) do
        plugin :yield_response, mode: "fast"
        route do |req, res|
          res.status = 401
          "Unauthorized"
        end
      end
      status("/").must_equal 401
    end

    it "still supports a single route block argument" do
      app(:bare) do
        plugin :yield_response, mode: "fast"
        route { |r| "OK" }
      end
      body("/").must_equal "OK"
    end

    it "is incompatible with the hooks plugin" do
      app(:hooks) { "OK" }
      app.plugin(:yield_response, mode: "fast")
      proc { body("/") }.must_raise(ArgumentError)
    end
  end

  describe "in its default configuration" do
    mock_logger = Class.new { attr_accessor :message }

    it "works with hooks when loaded last" do
      logger = mock_logger.new
      app(:bare) do
        plugin :hooks
        before { @user_id = 1 }
        after { logger.message = "loaded last" }
        plugin :yield_response
        route do |req, res|
          res.status = 401
          @user_id.to_s
        end
      end
      status, header, body = req
      status.must_equal 401
      body.must_equal ["1"]
      logger.message.must_equal "loaded last"
    end

    it "works with hooks when loaded first" do
      logger = mock_logger.new
      app(:bare) do
        plugin :yield_response
        plugin :hooks
        before { @user_id = 1 }
        after { logger.message = "loaded first" }
        route do |req, res|
          res.status = 401
          @user_id.to_s
        end
      end
      status, header, body = req
      status.must_equal 401
      body.must_equal ["1"]
      logger.message.must_equal "loaded first"
    end

    it "still supports a single route block argument" do
      app(:bare) do
        plugin :yield_response
        route { |r| "OK" }
      end

      status('/').must_equal(200)
    end
  end
end
