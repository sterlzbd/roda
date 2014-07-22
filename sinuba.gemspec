require File.expand_path("../lib/sinuba", __FILE__)

Gem::Specification.new do |s|
  s.name              = "sinuba"
  s.version           = Sinuba::VERSION.dup
  s.summary           = "Microframework for web applications"
  s.description       = "Sinuba is a microframework for web applications, inspired by Cuba and Sinatra."
  s.authors           = ["Jeremy Evans"]
  s.email             = ["code@jeremyevans.net"]
  s.homepage          = "https://github.com/jeremyevans/sinuba"
  s.license           = "MIT"

  s.files = %w'README.md MIT-LICENSE CHANGELOG lib/sinuba.rb' + Dir['lib/sinuba/*.rb']

  s.add_dependency "rack"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rack-test"
  s.add_development_dependency "tilt"
end
