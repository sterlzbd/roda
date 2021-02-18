require_relative "../spec_helper"
require 'fileutils'

run_tests = true
begin
  begin
    require 'tilt/sass'
  rescue LoadError
    begin
      for lib in %w'tilt sass'
        require lib
      end
    rescue LoadError
      warn "#{lib} not installed, skipping assets plugin test"
      run_tests = false
    end
  end
end

if run_tests
  metadata_file = File.expand_path('spec/assets/tmp/precompiled.json')
  describe 'recheck_precompiled_assets plugin' do
    define_method(:compile_assets) do |opts={}|
      Class.new(Roda) do
        plugin :assets, {:css => 'app.scss', :path => 'spec/assets/tmp', :css_dir=>nil, :precompiled=>metadata_file, :public=>'spec/assets/tmp', :prefix=>nil}.merge!(opts)
        compile_assets
      end
    end

    before do
      Dir.mkdir('spec/assets/tmp') unless File.directory?('spec/assets/tmp')
      FileUtils.cp('spec/assets/css/app.scss', 'spec/assets/tmp/app.scss')
      FileUtils.cp('spec/assets/js/head/app.js', 'spec/assets/tmp/app.js')
      compile_assets
      File.utime(Time.now, Time.now - 20, metadata_file)

      app(:bare) do
        plugin :assets, :public => 'spec/assets/tmp', :prefix=>nil, :precompiled=>metadata_file
        plugin :recheck_precompiled_assets

        route do |r|
          r.assets
          "#{assets(:css)}\n#{assets(:js)}"
        end
      end
    end
    after do
      FileUtils.rm_r('spec/assets/tmp') if File.directory?('spec/assets/tmp')
    end

    it 'should support :recheck_precompiled option to recheck precompiled file for new precompilation data' do
      css_hash = app.assets_opts[:compiled]['css']
      app.assets_opts[:compiled]['js'].must_be_nil
      body.scan("href=\"/app.#{css_hash}.css\"").length.must_equal 1
      body("/app.#{css_hash}.css").must_match(/color:\s*red/)

      File.write('spec/assets/tmp/app.scss', File.read('spec/assets/tmp/app.scss').sub('red', 'blue'))
      compile_assets
      File.utime(Time.now, Time.now - 10, metadata_file)

      app.assets_opts[:compiled]['css'].must_equal css_hash
      body.scan("href=\"/app.#{css_hash}.css\"").length.must_equal 1
      body("/app.#{css_hash}.css").must_match(/color:\s*red/)
      css2_hash = nil

      2.times do
        app.recheck_precompiled_assets
        css2_hash = app.assets_opts[:compiled]['css']
        css2_hash.wont_equal css_hash
        body.scan("href=\"/app.#{css2_hash}.css\"").length.must_equal 1
        body("/app.#{css2_hash}.css").must_match(/color:\s*blue/)
        body("/app.#{css_hash}.css").must_match(/color:\s*red/)
      end

      compile_assets(:js=>'app.js', :js_dir=>nil)
      app.recheck_precompiled_assets
      js_hash = app.assets_opts[:compiled]['js']
      body.scan("src=\"/app.#{js_hash}.js\"").length.must_equal 1
      body("/app.#{js_hash}.js").must_match(/console\.log\(.test.\)/)

      app.assets_opts[:compiled].replace({})
      app.compile_assets
      body.strip.must_be_empty
      app.plugin :assets, :css => 'app.scss', :path => 'spec/assets/tmp', :css_dir=>nil, :css_opts => {:cache=>false}
      app.compile_assets
      body.scan("href=\"/app.#{css2_hash}.css\"").length.must_equal 1
      body("/app.#{css2_hash}.css").must_match(/color:\s*blue/)
    end
  end

  describe 'recheck_precompiled_assets plugin' do
    it "should not allow loading if not using assets plugin" do
      proc{app(:recheck_precompiled_assets)}.must_raise Roda::RodaError
    end

    it "should not allow loading if using assets plugin without :precompiled option" do
      proc do
        app(:bare) do
          plugin :assets
          plugin :recheck_precompiled_assets
        end
      end.must_raise Roda::RodaError
    end
  end
end
