require File.expand_path("helper", File.dirname(__FILE__))

describe "capturing" do
  it "doesn't yield HOST" do
    app do |r|
      r.on :host=>"example.com" do |*args|
        args.size.to_s
      end
    end

    body("HTTP_HOST" => "example.com").should == '0'
  end

  it "doesn't yield the verb" do
    app do |r|
      r.get do |*args|
        args.size.to_s
      end
    end

    body.should == '0'
  end

  it "doesn't yield the path" do
    app do |r|
      r.get "home" do |*args|
        args.size.to_s
      end
    end

    body('/home').should == '0'
  end

  it "yields the segment" do
    app do |r|
      r.get "user", :id do |id|
        id
      end
    end

    body("/user/johndoe").should == 'johndoe'
  end

  it "yields a number" do
    app do |r|
      r.get "user", :id do |id|
        id
      end
    end

    body("/user/101").should == '101'
  end

  it "yield a file name with a matching extension" do
    app do |r|
      r.get "css", :extension=>"css" do |file|
        file
      end
    end

    body("/css/app.css").should == 'app'
  end

  it "yields a segment per nested block" do
    app do |r|
      r.on :one do |one|
        r.on :two do |two|
          r.on :three do |three|
            response.write one
            response.write two
            response.write three
          end
        end
      end
    end

    body("/one/two/three").should == "onetwothree"
  end

  it "consumes a slash if needed" do
    app do |r|
      r.get "(.+\\.css)" do |file|
        file
      end
    end

    body("/foo/bar.css").should == "foo/bar.css"
  end

  it "regex captures in string format" do
    app do |r|
      r.get "posts/(\\d+)-(.*)" do |id, slug|
        response.write id
        response.write slug
      end
    end

    body("/posts/123-postal-service").should == "123postal-service"
  end

  it "regex captures in regex format" do
    app do |r|
      r.get %r{posts/(\d+)-(.*)} do |id, slug|
        response.write id
        response.write slug
      end
    end

    body("/posts/123-postal-service").should == "123postal-service"
  end
end
