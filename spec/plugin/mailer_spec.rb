require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

begin
  require 'mail'
rescue LoadError
  warn "mail not installed, skipping mail plugin test"  
else
Mail.defaults do
  delivery_method :test
end

describe "mailer plugin" do 
  def deliveries
    Mail::TestMailer.deliveries
  end

  after do
    deliveries.clear
  end

  setup_email = lambda do 
    from "f@example.com"
    to "t@example.com"
    subject 's'
  end

  it "supports sending emails via the routing tree" do
    app(:mailer) do |r|
      r.mail do
        instance_exec(&setup_email)
        cc "c@example.com"
        bcc "b@example.com"
        response['X-Foo'] = 'Bar'
        "b"
      end
    end

    m = app.mail('/foo')
    deliveries.should == []
    m.from.should == ['f@example.com']
    m.to.should == ['t@example.com']
    m.cc.should == ['c@example.com']
    m.bcc.should == ['b@example.com']
    m.subject.should == 's'
    m.body.should == 'b'
    m.header['X-Foo'].to_s.should == 'Bar'

    m.deliver!
    deliveries.should == [m]

    deliveries.clear
    m = app.sendmail('/foo')
    deliveries.should == [m]
    m.from.should == ['f@example.com']
    m.to.should == ['t@example.com']
    m.cc.should == ['c@example.com']
    m.bcc.should == ['b@example.com']
    m.subject.should == 's'
    m.body.should == 'b'
    m.header['X-Foo'].to_s.should == 'Bar'
  end

  it "supports arguments to mail/sendmail methods, yielding them to the route blocks" do
    app(:mailer) do |r|
      instance_exec(&setup_email)
      r.mail "foo" do |*args|
        "foo#{args.inspect}"
      end
      r.mail :d do |*args|
        args.inspect
      end
    end

    app.mail('/foo', 1, 2).body.should == 'foo[1, 2]'
    app.sendmail('/bar', 1, 2).body.should == '["bar", 1, 2]'
  end

  it "supports attachments" do
    app(:mailer) do |r|
      r.mail do
        instance_exec(&setup_email)
        add_file __FILE__
      end
    end

    m = app.mail('foo')
    m.attachments.length.should == 1
    m.attachments.first.content_type.should =~ /mailer_spec\.rb/
    m.content_type.should =~ /\Amultipart\/mixed/
    m.parts.length.should == 1
    m.parts.first.body.should == File.read(__FILE__)
  end

  it "supports plain-text attachments with an email body" do
    app(:mailer) do |r|
      r.mail do
        instance_exec(&setup_email)
        add_file :filename=>'a.txt', :content=>'b'
        'c'
      end
    end

    m = app.mail('foo')
    m.parts.length.should == 2
    m.parts.first.content_type.should =~ /text\/plain/
    m.parts.first.body.should == 'c'
    m.parts.last.content_type.should =~ /text\/plain/
    m.parts.last.body.should == 'b'
    m.attachments.length.should == 1
    m.attachments.first.content_type.should =~ /a\.txt/
    m.content_type.should =~ /\Amultipart\/mixed/
  end

  it "supports regular web requests in same application" do
    app(:mailer) do |r|
      r.get "foo/:bar" do |bar|
        "foo#{bar}"
      end
      r.mail "bar" do
        instance_exec(&setup_email)
        "b"
      end
    end

    body("/foo/baz", 'rack.input'=>StringIO.new).should == 'foobaz'
    app.mail('/bar').body.should == 'b'
  end

  it "supports multipart email using text_part/html_pat" do
    app(:mailer) do |r|
      r.mail do
        instance_exec(&setup_email)
        text_part "t"
        html_part "h"
      end
    end

    m = app.mail('/foo')
    m.text_part.body.should == 't'
    m.html_part.body.should == 'h'
    m.content_type.should =~ /\Amultipart\/alternative/
  end

  it "supports setting arbitrary email headers for multipart emails" do
    app(:mailer) do |r|
      r.mail do
        instance_exec(&setup_email)
        text_part "t", "X-Text"=>'T'
        html_part "h", "X-HTML"=>'H'
      end
    end

    m = app.mail('/foo')
    m.text_part.body.should == 't'
    m.text_part.header['X-Text'].to_s.should == 'T'
    m.html_part.body.should == 'h'
    m.html_part.header['X-HTML'].to_s.should == 'H'
    m.content_type.should =~ /\Amultipart\/alternative/
  end

  it "raises error if mail object is not returned" do
    app(:mailer){}
    proc{app.mail('/')}.should raise_error(Roda::RodaPlugins::Mailer::Error)
  end

  it "does not raise an error when using an explicitly empty body" do
    app(:mailer){""}
    proc{app.mail('/')}.should_not raise_error
  end

  it "supports setting the default content-type for emails when loading the plugin" do
    app(:bare) do
      plugin :mailer, :content_type=>'text/html'
      route{""}
    end
    app.mail('/').content_type.should =~ /\Atext\/html/
  end

  it "supports loading the plugin multiple times" do
    app(:bare) do
      plugin :mailer, :content_type=>'text/html'
      plugin :mailer
      route{""}
    end
    app.mail('/').content_type.should =~ /\Atext\/html/
  end

  it "supports manually overridding the default content-type for emails" do
    app(:bare) do
      plugin :mailer, :content_type=>'text/html'
      route do
        response['Content-Type'] = 'text/foo'
        ""
      end
    end
    app.mail('/').content_type.should =~ /\Atext\/foo/
  end

  it "supports setting the default content type when attachments are used" do
    app(:bare) do
      plugin :mailer, :content_type=>'text/html'
      route do
        add_file 'spec/assets/css/raw.css'
        "a"
      end
    end
    m = app.mail('/')
    m.content_type.should =~ /\Amultipart\/mixed/
    m.parts.length.should == 2
    m.parts.first.content_type.should =~ /\Atext\/html/
    m.parts.first.body.should == "a"
    m.parts.last.content_type.should =~ /\Atext\/css/
    m.parts.last.body.should == File.read('spec/assets/css/raw.css')
  end
end
end
