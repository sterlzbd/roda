require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "path_rewriter plugin" do 
  it "allows rewriting remaining path or PATH_INFO" do
    app(:bare) do
      plugin :path_rewriter
      rewrite_path '/1', '/a'
      rewrite_path '/a', '/b'
      rewrite_path '/c', '/d', :path_info=>true
      rewrite_path '/2', '/1', :path_info=>true
      rewrite_path '/3', '/h'
      rewrite_path '/3', '/g', :path_info=>true
      rewrite_path /\A\/e\z/, '/f'
      route do |r|
        "#{r.path_info}:#{r.remaining_path}"
      end
    end

    body('/a').should == '/a:/b'
    body('/a/f').should == '/a/f:/b/f'
    body('/b').should == '/b:/b'
    body('/c').should == '/d:/d'
    body('/c/f').should == '/d/f:/d/f'
    body('/d').should == '/d:/d'
    body('/e').should == '/e:/f'
    body('/e/g').should == '/e/g:/e/g'
    body('/1').should == '/1:/b'
    body('/1/f').should == '/1/f:/b/f'
    body('/2').should == '/1:/b'
    body('/2/f').should == '/1/f:/b/f'
    body('/3').should == '/g:/g'
    
    app.freeze
    body('/a').should == '/a:/b'
    proc{app.rewrite_path '/a', '/b'}.should raise_error
  end
end
