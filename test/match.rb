require File.expand_path("helper", File.dirname(__FILE__))

describe "matchers" do
  it "should handle string with embedded param" do
    app do |r|
      r.on "posts/:id" do |id|
        id
      end
    end

    body('/posts/123').should == '123'
    status('/post/123').should == 404
  end

  it "should handle multiple params in single string" do
    app do |r|
      r.on "u/:uid/posts/:id" do |uid, id|
        uid + id
      end
    end

    body("/u/jdoe/posts/123").should == 'jdoe123'
    status("/u/jdoe/pots/123").should == 404
  end

  it "should handle regexes and nesting" do
    app do |r|
      r.on(/u\/(\w+)/) do |uid|
        r.on(/posts\/(\d+)/) do |id|
          uid + id
        end
      end
    end

    body("/u/jdoe/posts/123").should == 'jdoe123'
    status("/u/jdoe/pots/123").should == 404
  end

  it "should handle regex nesting colon param style" do
    app do |r|
      r.on(/u:(\w+)/) do |uid|
        r.on(/posts:(\d+)/) do |id|
          uid + id
        end
      end
    end

    body("/u:jdoe/posts:123").should == 'jdoe123'
    status("/u:jdoe/poss:123").should == 404
  end

  it "symbol matching" do
    app do |r|
      r.on "user", :id do |uid|
        r.on "posts", :pid do |id|
          uid + id
        end
      end
    end

    body("/user/jdoe/posts/123").should == 'jdoe123'
    status("/user/jdoe/pots/123").should == 404
  end

  it "paths and numbers" do
    app do |r|
      r.on "about" do
        r.on :one, :two do |one, two|
          one + two
        end
      end
    end

    body("/about/1/2").should == '12'
    status("/about/1").should == 404
  end

  it "paths and decimals" do
    app do |r|
     r.on "about" do
        r.on(/(\d+)/) do |one|
          one
        end
      end
    end

    body("/about/1").should == '1'
    status("/about/1.2").should == 404
  end
end
