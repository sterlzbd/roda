$:.unshift(File.expand_path("../lib", File.dirname(__FILE__)))

if RUBY_VERSION >= '3'
  begin
    require 'warning'
  rescue LoadError
  else
    Warning.ignore(%r{gems/(mail|minjs)-\d})
    Warning.dedup if Warning.respond_to?(:dedup)
  end
end

if ENV['COVERAGE']
  require 'coverage'
  require 'simplecov'

  def SimpleCov.roda_coverage(opts = {})
    start do
      enable_coverage :branch
      add_filter "/spec/"
      add_group('Missing'){|src| src.covered_percent < 100}
      add_group('Covered'){|src| src.covered_percent == 100}
    end
  end

  ENV.delete('COVERAGE')
  SimpleCov.roda_coverage
end

require_relative "../lib/roda"
require "stringio"

ENV['MT_NO_PLUGINS'] = '1' # Work around stupid autoloading of plugins
gem 'minitest'
require "minitest/global_expectations/autorun"

if ENV['CHECK_METHOD_VISIBILITY']
  require 'visibility_checker'
  VISIBILITY_CHANGES = []
  Minitest.after_run do
    if VISIBILITY_CHANGES.empty?
      puts "No visibility changes"
    else
      puts "Visibility changes:"
      VISIBILITY_CHANGES.uniq!{|v,| v}
      puts(*VISIBILITY_CHANGES.map do |v, caller|
        "#{caller}: #{v.new_visibility} method #{v.overridden_by}##{v.method} overrides #{v.original_visibility} method in #{v.defined_in}"
      end.sort)
    end
  end
end

$RODA_WARN = true
def (Roda::RodaPlugins).warn(s)
  return unless $RODA_WARN
  $stderr.puts s
  puts caller.grep(/_spec\.rb:\d+:/)
end

if ENV['RODA_RACK_SESSION_COOKIE'] != '1'
  require_relative '../lib/roda/session_middleware'
  DEFAULT_SESSION_MIDDLEWARE_ARGS =  [RodaSessionMiddleware, :secret=>'1'*64]
  DEFAULT_SESSION_ARGS = [:plugin, :sessions, :secret=>'1'*64]
else
  DEFAULT_SESSION_MIDDLEWARE_ARGS = [Rack::Session::Cookie, :secret=>'1']
  DEFAULT_SESSION_ARGS = [:use, Rack::Session::Cookie, :secret=>'1']
end

module CookieJar
  def req(path='/', env={})
    if path.is_a?(Hash)
      env = path
    else
      env['PATH_INFO'] = path.dup
    end
    env['HTTP_COOKIE'] = @cookie if @cookie

    a = super(env)
    if set = a[1]['Set-Cookie']
      @cookie = set.sub(/(; path=\/)?(; secure)?; HttpOnly/, '')
    end
    a
  end
end

class Minitest::Spec
  def self.deprecated(a, &block)
    it("#{a} (deprecated)") do
      begin
        $RODA_WARN = false
        instance_exec(&block)
      ensure
        $RODA_WARN = true
      end
    end
  end

  def app(type=nil, &block)
    case type
    when :new
      @app = _app{route(&block) if block}
    when :bare
      @app = _app(&block)
    when Symbol
      @app = _app do
        plugin type
        route(&block)
      end
    else
      if block
        @app = _app{route(&block)}
      else
        @app ||= _app{}
      end
    end
    if ENV['CHECK_METHOD_VISIBILITY']
      caller = caller_locations(1, 1)[0]
      [@app, @app::RodaRequest, @app::RodaResponse].each do |c|
        VISIBILITY_CHANGES.concat(VisibilityChecker.visibility_changes(c).map{|v| [v, "#{caller.path}:#{caller.lineno}"]})
      end
    end
    @app
  end

  def req(path='/', env={})
    if path.is_a?(Hash)
      env = path
    else
      env['PATH_INFO'] = path.dup
    end

    env = {"REQUEST_METHOD" => "GET", "PATH_INFO" => "/", "SCRIPT_NAME" => ""}.merge(env)
    @app.call(env)
  end
  
  def status(path='/', env={})
    req(path, env)[0]
  end

  def header(name, path='/', env={})
    req(path, env)[1][name]
  end

  def body(path='/', env={})
    s = String.new
    b = req(path, env)[2]
    b.each{|x| s << x}
    b.close if b.respond_to?(:close)
    s
  end

  def _app(&block)
    c = Class.new(Roda)
    c.class_eval(&block)
    c
  end

  def with_rack_env(env)
    ENV['RACK_ENV'] = env
    yield
  ensure
    ENV.delete('RACK_ENV')
  end
end
