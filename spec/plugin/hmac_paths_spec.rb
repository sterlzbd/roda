require_relative "../spec_helper"

describe "hmac_paths plugin" do 
  def hmac_paths_app(&block)
    app(:bare) do
      plugin :hmac_paths, secret: '1'*32
      route(&block)
    end
  end

  it "plugin requires :secret option be string at least 32 bytes for HMAC secret" do
    proc{app.plugin :hmac_paths}.must_raise Roda::RodaError
    proc{app.plugin :hmac_paths, secret: 1}.must_raise Roda::RodaError
    proc{app.plugin :hmac_paths, secret: '1'}.must_raise Roda::RodaError
    proc{app.plugin :hmac_paths, secret: '1'*31}.must_raise Roda::RodaError
  end

  it "plugin requires :old_secret option be string at least 32 bytes for HMAC secret if given" do
    proc{app.plugin :hmac_paths, secret: '1'*32, old_secret: 1}.must_raise Roda::RodaError
    proc{app.plugin :hmac_paths, secret: '1'*32, old_secret: '1'}.must_raise Roda::RodaError
    proc{app.plugin :hmac_paths, secret: '1'*32, old_secret: '1'*31}.must_raise Roda::RodaError
  end

  it "hmac_path method requires path argument be a string" do
    hmac_paths_app{|r| hmac_path(1)}
    proc{body}.must_raise Roda::RodaError
  end

  it "hmac_path method requires path argument must start with /" do
    hmac_paths_app{|r| hmac_path('1')}
    proc{body}.must_raise Roda::RodaError
  end

  it "hmac_path method returns path with HMAC" do
    hmac_paths_app{|r| hmac_path('/1')}
    body.must_equal "/1dd95fe7d0dbe409f852e81a7c2cc4c93971c04542a150c6baefe00876e28f13/0/1"
  end

  it "hmac_path HMAC depends on path argument" do
    hmac_paths_app do |r|
      r.get('a'){hmac_path('/2')}
      hmac_path('/1')
    end
    body.must_equal "/1dd95fe7d0dbe409f852e81a7c2cc4c93971c04542a150c6baefe00876e28f13/0/1"
    body('/a').must_equal "/adf4707dcc97605cdaeea144bba055ed330ae2d1d23025150d7cbf181af6cd63/0/2"
  end

  it "hmac_path method requires :root option be a string" do
    hmac_paths_app{|r| hmac_path('/1', root: 1)}
    proc{body}.must_raise Roda::RodaError
  end

  it "hmac_path method requires :root option must start with /" do
    hmac_paths_app{|r| hmac_path('/1', root: '1')}
    proc{body}.must_raise Roda::RodaError
  end

  it "hmac_path uses :root option for path prefix" do
    hmac_paths_app do |r|
      hmac_path('/1', root: '/foo')
    end
    body.must_equal "/foo/ee408306c4e9a5ba5e57d295fe5cbb2b82e252b636d67c2a15039cc265611210/0/1"
  end

  it "hmac_path HMAC depends on :root option" do
    hmac_paths_app do |r|
      r.get('a'){hmac_path('/1', root: '/bar')}
      hmac_path('/1', root: '/foo')
    end
    body.must_equal "/foo/ee408306c4e9a5ba5e57d295fe5cbb2b82e252b636d67c2a15039cc265611210/0/1"
    body('/a').must_equal "/bar/5ba0452a430fca1802eb93b52f2d994b58d768374ba318253cbc50c326e46f95/0/1"
  end

  it "hmac_path sets m flag for :method option" do
    hmac_paths_app do |r|
      hmac_path('/1', method: :get)
    end
    body.must_equal "/e21ef288ee8316f0d8e67eae55a2f27edda28316c3c231f4425281f6d291bccc/m/1"
  end

  it "hmac_path HMAC depends on :method option" do
    hmac_paths_app do |r|
      r.get('a'){hmac_path('/1', method: :post)}
      hmac_path('/1', method: :get)
    end
    body.must_equal "/e21ef288ee8316f0d8e67eae55a2f27edda28316c3c231f4425281f6d291bccc/m/1"
    body('/a').must_equal "/72644ba25f4253acbe5f26370ca948d31f8fa0041fc77ddc9dc92da22415d1cd/m/1"
  end

  it "hmac_path sets p flag and adds query string parameters for :params option" do
    hmac_paths_app do |r|
      hmac_path('/1', params: {foo: :bar})
    end
    body.must_equal "/503907ffeb039fa93b0e6d0728d30c2fef4b10d655aef6e1ac23347b2159443c/p/1?foo=bar"
  end

  it "hmac_path HMAC depends on :query option" do
    hmac_paths_app do |r|
      r.get('a'){hmac_path('/1', params: {bar: :foo})}
      hmac_path('/1', params: {foo: :bar})
    end
    body.must_equal "/503907ffeb039fa93b0e6d0728d30c2fef4b10d655aef6e1ac23347b2159443c/p/1?foo=bar"
    body('/a').must_equal "/1785c857e23dfd04c127162d292f557cd2db4b0a6ac9c39515c85ce9ff404165/p/1?bar=foo"
  end

  it "r.hmac_path does not yield if remaining path does not start with /" do
    hmac_paths_app{|r| r.hmac_path{r.remaining_path}}
    status('503907ffeb039fa93b0e6d0728d30c2fef4b10d655aef6e1ac23347b2159443c').must_equal 404
  end unless ENV['LINT']

  it "r.hmac_path does not yield if hmac segment is not 64 bytes" do
    hmac_paths_app{|r| r.hmac_path{r.remaining_path}}
    status('/503907ffeb039fa93b0e6d0728d30c2fef4b10d655aef6e1ac23347b2159443/0/').must_equal 404
  end

  it "r.hmac_path does not yield if there is no flags or empty flags segment" do
    hmac_paths_app{|r| r.hmac_path{r.remaining_path}}
    status('/503907ffeb039fa93b0e6d0728d30c2fef4b10d655aef6e1ac23347b2159443c').must_equal 404
    status('/503907ffeb039fa93b0e6d0728d30c2fef4b10d655aef6e1ac23347b2159443c/').must_equal 404
    status('/503907ffeb039fa93b0e6d0728d30c2fef4b10d655aef6e1ac23347b2159443c//').must_equal 404
  end

  it "r.hmac_path does not yield if there is no remaining path after flags segment" do
    hmac_paths_app{|r| r.hmac_path{r.remaining_path}}
    status('/503907ffeb039fa93b0e6d0728d30c2fef4b10d655aef6e1ac23347b2159443c/m').must_equal 404
  end

  it "r.hmac_path only yields if hmac path matches" do
    hmac_paths_app do |r|
      r.get 'path', String do |path|
        hmac_path("/#{path}", root: '')
      end

      r.hmac_path do
        r.remaining_path
      end
    end
    path = body('/path/1')
    body(path).must_equal '/1'
    status(path.chop + '2').must_equal 404
    status(path.sub(%r|./0/1\z|, '/0/1')).must_equal 404
    status(path.sub(%r|0/1\z|, '1/1')).must_equal 404
  end

  it "r.hmac_path does not support using path designed for one root with a different root" do
    hmac_paths_app do |r|
      r.get 'root', String do |root|
        hmac_path("/1", root: "/#{root}")
      end

      r.on Integer do
        r.hmac_path do
          r.remaining_path
        end
      end
    end
    root1_path = body('/root/1')
    root2_path = body('/root/2')
    status(root1_path.sub(/\A\/1/, '/2')).must_equal 404
    status(root2_path.sub(/\A\/2/, '/1')).must_equal 404
  end

  it "r.hmac_path for non-method-specific path works for any request method" do
    hmac_paths_app do |r|
      r.get 'path' do
        hmac_path("/1")
      end

      r.hmac_path do
        r.remaining_path
      end
    end
    path = body('/path')
    body(path).must_equal '/1'
    body(path, 'REQUEST_METHOD'=>'POST').must_equal '/1'
  end

  it "r.hmac_path for method-specific path only works for specified request method" do
    hmac_paths_app do |r|
      r.get 'method', String do |meth|
        hmac_path("/1", method: meth)
      end

      r.hmac_path do
        r.remaining_path
      end
    end
    get_path = body('/method/get')
    post_path = body('/method/post')
    body(get_path).must_equal '/1'
    body(post_path, 'REQUEST_METHOD'=>'POST').must_equal '/1'
    status(get_path, 'REQUEST_METHOD'=>'POST').must_equal 404
    status(post_path).must_equal 404
  end

  it "r.hmac_path for non-param-specific path only works with any query string" do
    hmac_paths_app do |r|
      r.get 'path' do
        hmac_path("/1")
      end

      r.hmac_path do
        r.remaining_path
      end
    end
    path = body('/path')
    body(path).must_equal '/1'
    body(path, 'QUERY_STRING'=>'a=b').must_equal '/1'
  end

  it "r.hmac_path for param-specific path only works for specified query string" do
    hmac_paths_app do |r|
      r.get 'params', String, String, String, String do |k1, v1, k2, v2|
        hmac_path("/1", params: {k1=>v1, k2=>v2})
      end

      r.hmac_path do
        r.remaining_path
      end
    end
    params1_path = body('/params/a/b/c/d')
    params2_path = body('/params/c/d/a/b')
    p1, qs1 = params1_path.split('?', 2)
    p2, qs2 = params2_path.split('?', 2)
    status(p1).must_equal 404
    status(p2).must_equal 404
    body(p1, 'QUERY_STRING'=>qs1).must_equal '/1'
    body(p2, 'QUERY_STRING'=>qs2).must_equal '/1'
    status(p1, 'QUERY_STRING'=>qs2).must_equal 404
    status(p2, 'QUERY_STRING'=>qs1).must_equal 404
  end

  it "r.hmac_path works as expected with :root, :method, and :params options" do
    hmac_paths_app do |r|
      r.get 'path', String, String, String, String do |r, m, k1, v1|
        hmac_path("/1", root: "/#{r}", method: m, params: {k1=>v1})
      end

      r.on Integer do
        r.hmac_path do
          r.remaining_path
        end
      end
    end
    path1 = body('/path/1/get/c/d')
    path2 = body('/path/2/post/a/b')
    p1, qs1 = path1.split('?', 2)
    p2, qs2 = path2.split('?', 2)
    body(p1, 'QUERY_STRING'=>qs1).must_equal '/1'
    body(p2, 'QUERY_STRING'=>qs2, 'REQUEST_METHOD'=>'POST').must_equal '/1'

    # No query string
    status(p1).must_equal 404
    status(p2).must_equal 404
    # Query string mismatch
    status(p1, 'QUERY_STRING'=>qs2).must_equal 404
    status(p2, 'QUERY_STRING'=>qs1, 'REQUEST_METHOD'=>'POST').must_equal 404
    # Request method mismatch
    status(p1, 'QUERY_STRING'=>qs1, 'REQUEST_METHOD'=>'POST').must_equal 404
    status(p2, 'QUERY_STRING'=>qs2).must_equal 404
    # Root mismatch
    status(p1.sub(/\A\/1/, '/2'), 'QUERY_STRING'=>qs1).must_equal 404
    status(p2.sub(/\A\/2/, '/1'), 'QUERY_STRING'=>qs2, 'REQUEST_METHOD'=>'POST').must_equal 404
  end

  it "r.hmac_path handles secret rotation using :old_secret option" do
    hmac_paths_app do |r|
      r.get 'path', String do |path|
        hmac_path("/#{path}", root: '')
      end

      r.hmac_path do
        r.remaining_path
      end
    end
    path = body('/path/1')
    body(path).must_equal '/1'
    app.plugin :hmac_paths, secret: '2'*32
    status(path).must_equal 404
    app.plugin :hmac_paths, secret: '2'*32, old_secret: '1'*32
    body(path).must_equal '/1'
    app.plugin :hmac_paths, secret: '2'*32, old_secret: '3'*32
    status(path).must_equal 404
  end

  it "example code in documation is accurate" do
    app(:bare) do
      plugin :hmac_paths, secret: 'some-secret-value-with-at-least-32-bytes'

      route do |r|
        r.on 'path' do
          r.on 'root', String do |root|
            hmac_path(r.remaining_path, root: "/#{root}")
          end

          r.on 'method', String do |method|
            hmac_path(r.remaining_path, method: method)
          end

          r.on 'params', String, String do |k, v|
            hmac_path(r.remaining_path, params: {k=>v})
          end

          r.on 'all', String, String, String, String do |root, method, k, v|
            hmac_path(r.remaining_path, root: "/#{root}", method: method, params: {k=>v})
          end

          hmac_path(r.remaining_path)
        end

        r.hmac_path do
          r.get 'widget', Integer do |widget_id|
            widget_id.to_s
          end
        end
      end
    end

    body('/path/widget/1').must_equal "/0c2feaefdfc80cc73da19b060c713d4193c57022815238c6657ce2d99b5925eb/0/widget/1"
    body('/path/root/widget/1').must_equal "/widget/daccafce3ce0df52e5ce774626779eaa7286085fcbde1e4681c74175ff0bbacd/0/1"
    body('/path/root/foobar/1').must_equal "/foobar/c5fdaf482771d4f9f38cc13a1b2832929026a4ceb05e98ed6a0cd5a00bf180b7/0/1"
    body('/path/method/get/widget/1').must_equal "/d38c1e634ecf9a3c0ab9d0832555b035d91b35069efcbf2670b0dfefd4b62fdd/m/widget/1"
    body('/path/params/foo/bar/widget/1').must_equal "/fe8d03f9572d5af6c2866295bd3c12c2ea11d290b1cbd016c3b68ee36a678139/p/widget/1?foo=bar"
    body('/path/all/widget/get/foo/bar/1').must_equal "/widget/9169af1b8f40c62a1c2bb15b1b377c65bda681b8efded0e613a4176387468c15/mp/1?foo=bar"
  end
end
