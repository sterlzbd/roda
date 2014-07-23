$:.unshift(File.expand_path("../lib", File.dirname(__FILE__)))

if ENV['COVERAGE']
  require 'coverage'
  require 'simplecov'

  def SimpleCov.sinuba_coverage(opts = {})
    start do
      add_filter "/spec/"
      add_group('Missing'){|src| src.covered_percent < 100}
      add_group('Covered'){|src| src.covered_percent == 100}
      yield self if block_given?
    end
  end

  ENV.delete('COVERAGE')
  SimpleCov.sinuba_coverage
end

require "sinuba"
require "stringio"

unless defined?(RSPEC_EXAMPLE_GROUP)
  if defined?(RSpec)
    require 'rspec/version'
    if RSpec::Version::STRING >= '2.11.0'
      RSpec.configure do |config|
        config.expect_with :rspec do |c|
          c.syntax = :should
        end
        config.mock_with :rspec do |c|
          c.syntax = :should
        end
      end
    end
    RSPEC_EXAMPLE_GROUP = RSpec::Core::ExampleGroup
  else
    RSPEC_EXAMPLE_GROUP = Spec::Example::ExampleGroup
  end
end

class RSPEC_EXAMPLE_GROUP
  def app(type=nil, &block)
    case type
    when :new
      @app = Sinuba.define{route(&block)}
    when :bare
      @app = Sinuba.define(&block)
    when Symbol
      @app = Sinuba.define do
        plugin type
        route(&block)
      end
    else
      @app ||= Sinuba.define{route(&block)}
    end
  end

  
  def req(path='/', env={})
    if path.is_a?(Hash)
      env = path
    else
      env['PATH_INFO'] = path
    end

    env = {"REQUEST_METHOD" => "GET", "PATH_INFO" => "/", "SCRIPT_NAME" => ""}.merge(env)
    app.call(env)
  end
  
  def status(path='/', env={})
    req(path, env)[0]
  end

  def header(name, path='/', env={})
    req(path, env)[1][name]
  end

  def body(path='/', env={})
    req(path, env)[2].join
  end
end
