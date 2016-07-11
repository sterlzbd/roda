# frozen_string_literal: true

require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "extension_response plugin" do
  before do
    app(:extension_response) do |r|
      r.is 'a' do
        r.html{ "HTML: #{r.requested_type}" }
        r.json{ "JSON: #{r.requested_type}" }
        r.xml{ "XML: #{r.requested_type}" }
        "No match"
      end
    end
  end

  it "uses the file extension in the path" do
    body('/a').must_equal 'HTML: html'
    header('Content-Type', '/a').must_equal 'text/html'

    body('/a.html').must_equal 'HTML: html'
    header('Content-Type', '/a.html').must_equal 'text/html'

    body('/a.json').must_equal 'JSON: json'
    header('Content-Type', '/a.json').must_equal 'application/json'

    body('/a.xml').must_equal 'XML: xml'
    header('Content-Type', '/a.xml').must_equal 'application/xml'

    status('/a.yadda').must_equal 404
  end

  it "uses the Accept header value" do
    body('/a', 'HTTP_ACCEPT' => 'text/html').must_equal 'HTML: html'
    header('Content-Type', '/a', 'HTTP_ACCEPT' => 'text/html').must_equal 'text/html'

    body('/a', 'HTTP_ACCEPT' => 'application/json').must_equal 'JSON: json'
    header('Content-Type', '/a', 'HTTP_ACCEPT' => 'application/json').must_equal 'application/json'

    body('/a', 'HTTP_ACCEPT' => 'application/xml').must_equal 'XML: xml'
    header('Content-Type', '/a', 'HTTP_ACCEPT' => 'application/xml').must_equal 'application/xml'

    body('/a', 'HTTP_ACCEPT' => 'some/thing').must_equal 'HTML: html'
    header('Content-Type', '/a', 'HTTP_ACCEPT' => 'some/thing').must_equal 'text/html'
  end

  it "favors the file extension over the Accept header" do
    body('/a.json', 'HTTP_ACCEPT' => 'text/html').must_equal 'JSON: json'
    body('/a.xml', 'HTTP_ACCEPT' => 'application/json').must_equal 'XML: xml'
    body('/a.html', 'HTTP_ACCEPT' => 'application/xml').must_equal 'HTML: html'
  end


  it "uses the default if neither file extension nor Accept header are given" do
    body('/a').must_equal 'HTML: html'
    header('Content-Type', '/a').must_equal 'text/html'
  end
end

describe "extension_response plugin" do
  it "does not use the file extension if its disabled" do
    app(:bare) do
      plugin :extension_response, :use_extension => false

      route do |r|
        r.is 'a' do
          r.html{ "HTML" }
          r.json{ "JSON" }
        end
      end
    end

    status('/a.json').must_equal 404
    status('/a.html').must_equal 404
    body('/a', 'HTTP_ACCEPT' => 'text/html').must_equal 'HTML'
    body('/a', 'HTTP_ACCEPT' => 'application/json').must_equal 'JSON'
  end

  it "does not use the Accept header if its disabled" do
    app(:bare) do
      plugin :extension_response, :use_header => false

      route do |r|
        r.is 'a' do
          r.html{ "HTML" }
          r.json{ "JSON" }
        end
      end
    end

    body('/a', 'HTTP_ACCEPT' => 'text/html').must_equal 'HTML'
    body('/a', 'HTTP_ACCEPT' => 'application/json').must_equal 'HTML'
    body('/a.html', 'HTTP_ACCEPT' => 'application/json').must_equal 'HTML'
    body('/a.json', 'HTTP_ACCEPT' => 'text/html').must_equal 'JSON'
  end

  it "only eats known file extensions" do
    app(:bare) do
      plugin :extension_response

      route do |r|
        r.is 'a' do
          r.html{ "HTML" }
          r.json{ "JSON" }
          r.xml{ "XML" }
          raise "Mismatch!"
        end

        r.is 'a.jpg' do
          "Okay"
        end
      end
    end

    body('/a.html').must_equal 'HTML'
    body('/a.json').must_equal 'JSON'
    body('/a.xml').must_equal 'XML'
    body('/a.jpg').must_equal 'Okay'
  end

  it "uses custom data types" do
    app(:bare) do
      plugin :extension_response, :types => { :yaml => 'application/x-yaml' }

      route do |r|
        r.is 'a' do
          r.html{ "HTML" }
          r.extension(:yaml){ "YAML" }
          raise "Mismatch!"
        end
      end
    end

    body('/a.html').must_equal 'HTML'
    body('/a.yaml').must_equal 'YAML'
    header('Content-Type', '/a.yaml').must_equal 'application/x-yaml'
  end

  it "uses custom default value" do
    app(:bare) do
      plugin :extension_response, :default => :json

      route do |r|
        r.is 'a' do
          r.html{ "HTML" }
          r.json{ "JSON" }
          raise "Mismatch!"
        end
      end
    end

    body('/a').must_equal 'JSON'
    body('/a.html').must_equal 'HTML'
    body('/a.json').must_equal 'JSON'
  end

  it "excludes given types" do
    app(:bare) do
      plugin :extension_response, :exclude => [ :xml ]

      route do |r|
        r.is 'a' do
          r.html{ "HTML" }
          r.json{ "JSON" }
          r.xml{ raise "Mismatch!" }
          raise "Mismatch"
        end
      end
    end

    body('/a.html').must_equal 'HTML'
    body('/a.json').must_equal 'JSON'
    status('/a.xml').must_equal 404

    body('/a', 'HTTP_ACCEPT' => 'text/xml').must_equal 'HTML'
    body('/a', 'HTTP_ACCEPT' => 'application/json').must_equal 'JSON'
    body('/a', 'HTTP_ACCEPT' => 'text/xml').must_equal 'HTML'
    body('/a', 'HTTP_ACCEPT' => 'application/xml').must_equal 'HTML'
  end
end
