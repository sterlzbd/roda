require File.expand_path("../lib/roda", __FILE__)

Gem::Specification.new do |s|
  s.name              = "roda"
  s.version           = Roda::RodaVersion.dup
  s.summary           = "Routing tree web framework"
  s.description       = "Routing tree web framework, inspired by Sinatra and Cuba"
  s.authors           = ["Jeremy Evans"]
  s.email             = ["code@jeremyevans.net"]
  s.homepage          = "https://github.com/jeremyevans/roda"
  s.license           = "MIT"

  s.files = %w'README.md MIT-LICENSE CHANGELOG Rakefile' + Dir['{lib,spec}/**/*.rb']

  s.add_dependency "rack"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rack-test"
  s.add_development_dependency "sinatra-flash"
  s.add_development_dependency "tilt"
end
