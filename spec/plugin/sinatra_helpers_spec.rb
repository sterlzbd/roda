require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

require 'uri'

describe "sinatra_helpers plugin" do 
  def sin_app(&block)
    app(:sinatra_helpers, &block)
  end

  def status_app(code, &block)
    #code += 2 if [204, 205, 304].include? code
    block ||= proc{}
    sin_app do |r|
      status code
      instance_eval(&block).inspect
    end
  end

  it 'status returns the response status code if not given an argument' do
    status_app(207){status}
    body.should == "207"
  end

  it 'status sets the response status code if given an argument' do
    status_app 207
    status.should == 207
  end

  it 'not_found? is true only if status == 404' do
    status_app(404){not_found?}
    body.should == 'true'
    status_app(405){not_found?}
    body.should == 'false'
    status_app(403){not_found?}
    body.should == 'false'
  end

  it 'informational? is true only for 1xx status' do
    status_app(100 + rand(100)){informational?}
    body.should == 'true'
    status_app(200 + rand(400)){informational?}
    body.should == 'false'
  end

  it 'success? is true only for 2xx status' do
    status_app(200 + rand(100)){success?}
    body.should == 'true'
    status_app(100 + rand(100)){success?}
    body.should == 'false'
    status_app(300 + rand(300)){success?}
    body.should == 'false'
  end

  it 'redirect? is true only for 3xx status' do
    status_app(300 + rand(100)){redirect?}
    body.should == 'true'
    status_app(200 + rand(100)){redirect?}
    body.should == 'false'
    status_app(400 + rand(200)){redirect?}
    body.should == 'false'
  end

  it 'client_error? is true only for 4xx status' do
    status_app(400 + rand(100)){client_error?}
    body.should == 'true'
    status_app(200 + rand(200)){client_error?}
    body.should == 'false'
    status_app(500 + rand(100)){client_error?}
    body.should == 'false'
  end

  it 'server_error? is true only for 5xx status' do
    status_app(500 + rand(100)){server_error?}
    body.should == 'true'
    status_app(200 + rand(300)){server_error?}
    body.should == 'false'
  end

  describe 'body' do
    it 'takes a block for deferred body generation' do
      sin_app{body{'Hello World'}; nil}
      body.should == 'Hello World'
      header('Content-Length').should == '11'
    end

    it 'supports #join' do
      sin_app{body{'Hello World'}; nil}
      req[2].join.should == 'Hello World'
    end

    it 'takes a String, Array, or other object responding to #each' do
      sin_app{body 'Hello World'; nil}
      body.should == 'Hello World'
      header('Content-Length').should == '11'

      sin_app{body ['Hello ', 'World']; nil}
      body.should == 'Hello World'
      header('Content-Length').should == '11'

      o = Object.new
      def o.each; yield 'Hello World' end
      sin_app{body o; nil}
      body.should == 'Hello World'
      header('Content-Length').should == '11'
    end
  end

  describe 'redirect' do
    it 'uses a 302 when only a path is given' do
      sin_app do
        redirect '/foo'
        fail 'redirect should halt'
      end

      status.should == 302
      body.should == ''
      header('Location').should == '/foo'
    end

    it 'adds script_name if given a path' do
      sin_app{redirect "/foo"}
      header('Location', '/bar', 'SCRIPT_NAME'=>'/foo').should == '/foo'
    end

    it 'does not adds script_name if not given a path' do
      sin_app{redirect}
      header('Location', '/bar', 'SCRIPT_NAME'=>'/foo', 'REQUEST_METHOD'=>'POST').should == '/foo/bar'
    end

    it 'respects :absolute_redirects option' do
      sin_app{redirect}
      app.opts[:absolute_redirects] = true
      header('Location', '/bar', 'HTTP_HOST'=>'example.org', 'SCRIPT_NAME'=>'/foo', 'REQUEST_METHOD'=>'POST').should == 'http://example.org/foo/bar'
    end

    it 'respects :prefixed_redirects option' do
      sin_app{redirect "/bar"}
      app.opts[:prefixed_redirects] = true
      header('Location', 'SCRIPT_NAME'=>'/foo').should == '/foo/bar'
    end

    it 'ignores :prefix_redirects option if not given a path' do
      sin_app{redirect}
      app.opts[:prefix_redirects] = true
      header('Location', "/bar", 'SCRIPT_NAME'=>'/foo', 'REQUEST_METHOD'=>'POST').should == '/foo/bar'
    end

    it 'uses the code given when specified' do
      sin_app{redirect '/foo', 301}
      status.should == 301
    end

    it 'redirects back to request.referer when passed back' do
      sin_app{redirect back}
      header('Location', 'HTTP_REFERER' => '/foo').should == '/foo'
    end

    it 'uses 303 for post requests if request is HTTP 1.1, 302 for 1.0' do
      sin_app{redirect '/foo'}
      status('HTTP_VERSION' => 'HTTP/1.1', 'REQUEST_METHOD'=>'POST').should == 303
      status('HTTP_VERSION' => 'HTTP/1.0', 'REQUEST_METHOD'=>'POST').should == 302
    end
  end

  describe 'error' do
    it 'sets a status code and halts' do
      sin_app do
        error
        fail 'error should halt'
      end

      status.should == 500
      body.should == ''
    end

    it 'accepts status code' do
      sin_app{error 501}
      status.should == 501
      body.should == ''
    end

    it 'accepts body' do
      sin_app{error '501'}
      status.should == 500
      body.should == '501'
    end

    it 'accepts status code and body' do
      sin_app{error 502, '501'}
      status.should == 502
      body.should == '501'
    end
  end

  describe 'not_found' do
    it 'halts with a 404 status' do
      sin_app do
        not_found
        fail 'not_found should halt'
      end

      status.should == 404
      body.should == ''
    end

    it 'accepts optional body' do
      sin_app{not_found 'nf'}
      status.should == 404
      body.should == 'nf'
    end
  end

  describe 'headers' do
    it 'sets headers on the response object when given a Hash' do
      sin_app do
        headers 'X-Foo' => 'bar'
        'kthx'
      end

      header('X-Foo').should == 'bar'
      body.should == 'kthx'
    end

    it 'returns the response headers hash when no hash provided' do
      sin_app{headers['X-Foo'] = 'bar'}
      header('X-Foo').should == 'bar'
    end
  end

  describe 'mime_type' do
    before do
      sin_app{|r| mime_type(r.path).to_s}
    end

    it "looks up mime types in Rack's MIME registry" do
      Rack::Mime::MIME_TYPES['.foo'] = 'application/foo'
      body('foo').should == 'application/foo'
      body(:foo).should == 'application/foo'
      body('.foo').should == 'application/foo'
    end

    it 'returns nil when given nil' do
      body('PATH_INFO'=>nil).should == ''
    end

    it 'returns nil when media type not registered' do
      body('bizzle').should == ''
    end

    it 'returns the argument when given a media type string' do
      body('text/plain').should == 'text/plain'
    end

    it 'supports mime types registered at the class level' do
      app.mime_type :foo, 'application/foo'
      body(:foo).should == 'application/foo'
    end
  end

  describe 'content_type' do
    it 'sets the Content-Type header' do
      sin_app do
        content_type 'text/plain'
        'Hello World'
      end

      header('Content-Type').should == 'text/plain'
      body.should == 'Hello World'
    end

    it 'takes media type parameters (like charset=)' do
      sin_app{content_type 'text/html', :charset => 'latin1'}
      header('Content-Type').should == 'text/html;charset=latin1'
    end

    it "looks up symbols in Rack's mime types dictionary" do
      sin_app{content_type :foo}
      Rack::Mime::MIME_TYPES['.foo'] = 'application/foo'
      header('Content-Type').should == 'application/foo'
    end

    it 'fails when no mime type is registered for the argument provided' do
      sin_app{content_type :bizzle}
      proc{body}.should raise_error(Roda::RodaError)
    end

    it 'handles already present params' do
      sin_app{content_type 'foo/bar;level=1', :charset => 'utf-8'}
      header('Content-Type').should == 'foo/bar;level=1, charset=utf-8'
    end

    it 'does not add charset if present' do
      sin_app{content_type 'text/plain;charset=utf-16', :charset => 'utf-8'}
      header('Content-Type').should == 'text/plain;charset=utf-16'
    end

    it 'properly encodes parameters with delimiter characters' do
      sin_app{|r| content_type 'image/png', :comment => r.path }
      header('Content-Type', 'Hello, world!').should == 'image/png;comment="Hello, world!"'
      header('Content-Type', 'semi;colon').should == 'image/png;comment="semi;colon"'
      header('Content-Type', '"Whatever."').should == 'image/png;comment="\"Whatever.\""'
    end
  end

  describe 'attachment' do
    before do
      sin_app{|r| attachment r.path; 'b'}
    end

    it 'sets the Content-Disposition header' do
      header('Content-Disposition', '/foo/test.xml').should == 'attachment; filename="test.xml"'
      body.should == 'b'
    end

    it 'sets the Content-Disposition header even when a filename is not given' do
      sin_app{attachment}
      header('Content-Disposition', '/foo/test.xml').should == 'attachment'
    end

    it 'sets the Content-Type header' do
      header('Content-Type', 'test.xml').should == 'application/xml'
    end

    it 'does not modify the default Content-Type without a file extension' do
      header('Content-Type', 'README').should == 'text/html'
    end

    it 'should not modify the Content-Type if it is already set' do
      sin_app do
        content_type :atom
        attachment 'test.xml'
      end

      header('Content-Type', 'README').should == 'application/atom+xml'
    end
  end

  describe 'send_file' do
    before(:all) do
      file = @file = 'spec/assets/css/raw.css'
      @content = File.read(@file)
      sin_app{send_file file, env['OPTS'] || {}}
    end

    it "sends the contents of the file" do
      status.should == 200
      body.should == @content
    end

    it 'sets the Content-Type response header if a mime-type can be located' do
      header('Content-Type').should == 'text/css'
    end

    it 'sets the Content-Type response header if type option is set to a file extension' do
      header('Content-Type', 'OPTS'=>{:type => 'html'}).should == 'text/html'
    end

    it 'sets the Content-Type response header if type option is set to a mime type' do
      header('Content-Type', 'OPTS'=>{:type => 'application/octet-stream'}).should == 'application/octet-stream'
    end

    it 'sets the Content-Length response header' do
      header('Content-Length').should == @content.length.to_s
    end

    it 'sets the Last-Modified response header' do
      header('Last-Modified').should == File.mtime(@file).httpdate
    end

    it 'allows passing in a different Last-Modified response header with :last_modified' do
      time = Time.now
      @app.plugin :caching
      header('Last-Modified', 'OPTS'=>{:last_modified => time}).should == time.httpdate
    end

    it "returns a 404 when not found" do
      sin_app{send_file 'this-file-does-not-exist.txt'}
      status.should == 404
    end

    it "does not set the Content-Disposition header by default" do
      header('Content-Disposition').should == nil
    end

    it "sets the Content-Disposition header when :disposition set to 'attachment'" do
      header('Content-Disposition', 'OPTS'=>{:disposition => 'attachment'}).should == 'attachment; filename="raw.css"'
    end

    it "does not set add a file name if filename is false" do
      header('Content-Disposition', 'OPTS'=>{:disposition => 'inline', :filename=>false}).should == 'inline'
    end

    it "sets the Content-Disposition header when :disposition set to 'inline'" do
      header('Content-Disposition', 'OPTS'=>{:disposition => 'inline'}).should == 'inline; filename="raw.css"'
    end

    it "sets the Content-Disposition header when :filename provided" do
      header('Content-Disposition', 'OPTS'=>{:filename => 'foo.txt'}).should == 'attachment; filename="foo.txt"'
    end

    it 'allows setting a custom status code' do
      status('OPTS'=>{:status=>201}).should == 201
    end

    it "is able to send files with unknown mime type" do
      header('Content-Type', 'OPTS'=>{:type => '.foobar'}).should == 'application/octet-stream'
    end

    it "does not override Content-Type if already set and no explicit type is given" do
      file = @file
      sin_app do
        content_type :png
        send_file file
      end
      header('Content-Type').should == 'image/png'
    end

    it "does override Content-Type even if already set, if explicit type is given" do
      file = @file
      sin_app do
        content_type :png
        send_file file, :type => :gif
      end
      header('Content-Type').should == 'image/gif'
    end
  end

  describe 'uri' do
    describe "without arguments" do
      before do
        sin_app{uri}
      end

      it 'generates absolute urls' do
        body('HTTP_HOST'=>'example.org').should == 'http://example.org/'
      end

      it 'includes path_info' do
        body('/foo', 'HTTP_HOST'=>'example.org').should == 'http://example.org/foo'
      end

      it 'includes script_name' do
        body('/bar', 'HTTP_HOST'=>'example.org', "SCRIPT_NAME" => '/foo').should == 'http://example.org/foo/bar'
      end

      it 'handles standard HTTP and HTTPS ports' do
        body('SERVER_NAME'=>'example.org', 'SERVER_PORT' => '80').should == 'http://example.org/'
        body('SERVER_NAME'=>'example.org', 'SERVER_PORT' => '443', 'HTTPS'=>'on').should == 'https://example.org/'
      end

      it 'handles non-standard HTTP port' do
        body('SERVER_NAME'=>'example.org', 'SERVER_PORT' => '81').should == 'http://example.org:81/'
        body('SERVER_NAME'=>'example.org', 'SERVER_PORT' => '443').should == 'http://example.org:443/'
      end

      it 'handles non-standard HTTPS port' do
        body('SERVER_NAME'=>'example.org', 'SERVER_PORT' => '444', 'HTTPS'=>'on').should == 'https://example.org:444/'
        body('SERVER_NAME'=>'example.org', 'SERVER_PORT' => '80', 'HTTPS'=>'on').should == 'https://example.org:80/'
      end

      it 'handles reverse proxy' do
        body('SERVER_NAME'=>'example.org', 'HTTP_X_FORWARDED_HOST' => 'example.com', 'SERVER_PORT' => '8080').should == 'http://example.com/'
      end
    end

    it 'allows passing an alternative to path_info' do
      sin_app{uri '/bar'}
      body('HTTP_HOST'=>'example.org').should == 'http://example.org/bar'
      body('HTTP_HOST'=>'example.org', "SCRIPT_NAME" => '/foo').should == 'http://example.org/foo/bar'
    end

    it 'handles absolute URIs' do
      sin_app{uri 'http://google.com'}
      body('HTTP_HOST'=>'example.org').should == 'http://google.com'
    end

    it 'handles different protocols' do
      sin_app{uri 'mailto:jsmith@example.com'}
      body('HTTP_HOST'=>'example.org').should == 'mailto:jsmith@example.com'
    end

    it 'allows turning off host' do
      sin_app{uri '/foo', false}
      body('HTTP_HOST'=>'example.org').should == '/foo'
      body('HTTP_HOST'=>'example.org', "SCRIPT_NAME" => '/bar').should == '/bar/foo'
    end

    it 'allows turning off script_name' do
      sin_app{uri '/foo', true, false}
      body('HTTP_HOST'=>'example.org').should == 'http://example.org/foo'
      body('HTTP_HOST'=>'example.org', "SCRIPT_NAME" => '/bar').should == 'http://example.org/foo'
    end

    it 'is aliased to #url' do
      sin_app{url}
      body('HTTP_HOST'=>'example.org').should == 'http://example.org/'
    end

    it 'is aliased to #to' do
      sin_app{to}
      body('HTTP_HOST'=>'example.org').should == 'http://example.org/'
    end

    it 'accepts a URI object instead of a String' do
      sin_app{uri URI.parse('http://roda.jeremyevans.net')}
      body.should == 'http://roda.jeremyevans.net'
    end
  end

  it 'logger logs to rack.logger' do
    sin_app{logger.info "foo"}
    o = Object.new
    def o.method_missing(*a)
      (@a ||= []) << a
    end
    def o.logs
      @a
    end

    status('rack.logger'=>o).should == 404
    o.logs.should == [[:info, 'foo']]
  end

  it 'supports disabling delegation if :delegate=>false option is provided' do
    app(:bare) do
      plugin :sinatra_helpers, :delegate=>false
      route do |r|
        r.root{content_type}
        r.is("req"){r.ssl?.to_s}
        r.is("res"){response.not_found?.inspect}
      end
    end

    proc{body}.should raise_error(NameError)
    body('/req').should == 'false'
    body('/res').should == 'nil'
  end
end

