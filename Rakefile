require "rake"
require "rake/clean"

NAME = 'roda'
VERS = lambda do
  require File.expand_path("../lib/roda/version.rb", __FILE__)
  Roda::RodaVersion
end
CLEAN.include ["#{NAME}-*.gem", "rdoc", "coverage", "www/public/*.html", "www/public/rdoc", "spec/assets/app.*.css", "spec/assets/app.*.js", "spec/assets/app.*.css.gz", "spec/assets/app.*.js.gz"]

# Gem Packaging and Release

desc "Packages #{NAME}"
task :package=>[:clean] do |p|
  sh %{gem build #{NAME}.gemspec}
end

### RDoc

RDOC_DEFAULT_OPTS = ["--line-numbers", "--inline-source", '--title', 'Roda: Routing tree web framework toolkit']

begin
  gem 'hanna-nouveau'
  RDOC_DEFAULT_OPTS.concat(['-f', 'hanna'])
rescue Gem::LoadError
end

rdoc_task_class = begin
  require "rdoc/task"
  RDoc::Task
rescue LoadError
  require "rake/rdoctask"
  Rake::RDocTask
end

RDOC_OPTS = RDOC_DEFAULT_OPTS + ['--main', 'README.rdoc']
RDOC_FILES = %w"README.rdoc CHANGELOG MIT-LICENSE lib/**/*.rb" + Dir["doc/*.rdoc"] + Dir['doc/release_notes/*.txt']

rdoc_task_class.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.options += RDOC_OPTS
  rdoc.rdoc_files.add RDOC_FILES
end

rdoc_task_class.new(:website_rdoc) do |rdoc|
  rdoc.rdoc_dir = "www/public/rdoc"
  rdoc.options += RDOC_OPTS
  rdoc.rdoc_files.add RDOC_FILES
end

### Website

desc "Make local version of website"
task :website_base do
  sh %{#{FileUtils::RUBY} -I lib www/make_www.rb}
end

desc "Make local version of website, with rdoc"
task :website => [:website_base, :website_rdoc]

desc "Make local version of website"
task :serve => :website do
  sh %{#{FileUtils::RUBY} -C www -S rackup}
end


### Specs

spec = proc do |env|
  env.each{|k,v| ENV[k] = v}
  sh "#{FileUtils::RUBY} -rubygems -I lib -e 'ARGV.each{|f| require f}' ./spec/*_spec.rb ./spec/plugin/*_spec.rb"
  env.each{|k,v| ENV.delete(k)}
end

desc "Run specs"
task "spec" do
  spec.call({})
end

task :default=>:spec

desc "Run specs with coverage"
task "spec_cov" do
  spec.call('COVERAGE'=>'1')
end
  
desc "Run specs with -w, some warnings filtered"
task "spec_w" do
  ENV['RUBYOPT'] ? (ENV['RUBYOPT'] += " -w") : (ENV['RUBYOPT'] = '-w')
  rake = ENV['RAKE'] || "#{FileUtils::RUBY} -S rake"
  sh %{#{rake} 2>&1 | egrep -v \": warning: instance variable @.* not initialized|: warning: method redefined; discarding old|: warning: previous definition of|: warning: statement not reached"}
end

### Other

desc "Print #{NAME} version"
task :version do
  puts VERS.call
end

desc "Start an IRB shell using the extension"
task :irb do
  require 'rbconfig'
  ruby = ENV['RUBY'] || File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name'])
  irb = ENV['IRB'] || File.join(RbConfig::CONFIG['bindir'], File.basename(ruby).sub('ruby', 'irb'))
  sh %{#{irb} -I lib -r #{NAME}}
end


