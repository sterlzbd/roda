require File.expand_path("helper", File.dirname(__FILE__))

describe "segment handling" do
  before do
    app do |r|
      r.on "post" do
        r.on :id do |id|
          id
        end
      end
    end
  end

  it "matches numeric ids" do
    body('/post/1').should == '1'
  end

  it "matches decimal numbers" do
    body('/post/1.1').should == '1.1'
  end

  it "matches slugs" do
    body('/post/my-blog-post-about-cuba').should == 'my-blog-post-about-cuba'
  end

  it "matches only the first segment available" do
    body('/post/one/two/three').should == 'one'
  end
end
