require File.expand_path("../lib/roda/version", __FILE__)

Gem::Specification.new do |s|
  s.name              = "roda"
  s.version           = Roda::RodaVersion.dup
  s.summary           = "Routing tree web toolkit"
  s.authors           = ["Jeremy Evans"]
  s.email             = ["code@jeremyevans.net"]
  s.homepage          = "http://roda.jeremyevans.net"
  s.license           = "MIT"
  s.required_ruby_version = ">= 1.9.2"

  s.files = %w'README.rdoc MIT-LICENSE CHANGELOG Rakefile' + Dir['doc/*.rdoc'] + Dir['doc/release_notes/*.txt'] + Dir['{lib,spec}/**/*.rb'] + Dir['spec/views/*'] + Dir['spec/assets/{css/{app.scss,raw.css,no_access.css},js/head/app.js}']
  s.extra_rdoc_files = %w'README.rdoc MIT-LICENSE CHANGELOG' + Dir["doc/*.rdoc"] + Dir['doc/release_notes/*.txt']

  s.add_dependency "rack"
  s.add_development_dependency "rake"
  s.add_development_dependency "minitest", ">= 5.7.0"
  s.add_development_dependency "tilt"
  s.add_development_dependency "erubi"
  s.add_development_dependency "haml"
  s.add_development_dependency "rack_csrf"
  s.add_development_dependency "sass"
  s.add_development_dependency "json"
  s.add_development_dependency "mail"
end
