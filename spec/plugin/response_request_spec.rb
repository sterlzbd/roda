require_relative "../spec_helper"

describe "response_request plugin" do
  it "gives the response access to the request" do
    app(:response_request) do
      response.request.post? ? "b" : "a"
    end

    body.must_equal "a"
    body('REQUEST_METHOD'=>'POST').must_equal "b"
  end
end
