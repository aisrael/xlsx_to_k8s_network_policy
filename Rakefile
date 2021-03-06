# frozen_string_literal: true

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  warn e.message
  warn 'Run `bundle install` to install missing gems'
  exit e.status_code
end
require 'rake'
require 'juwelier'
Juwelier::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://guides.rubygems.org/specification-reference/ for more options
  gem.name = 'xlsx_to_k8s_network_policy'
  gem.homepage = 'http://github.com/aisrael/xlsx_to_k8s_network_policy'
  gem.license = 'MIT'
  gem.summary = %(Generate Kubernetes Network Policy from Excel)
  gem.description = %(Generate Kubernetes Network Policy YAML resource definitions from .xlsx Excel spreadsheets)
  gem.email = 'aisrael@gmail.com'
  gem.authors = ['Alistair A. Israel']
  gem.files.exclude '.*'
  gem.files.exclude 'test/**/*'
  gem.files.exclude 'spec/**/*'

  # dependencies defined in Gemfile
end
Juwelier::RubygemsDotOrgTasks.new
require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

desc 'Code coverage detail'
task :simplecov do
  ENV['COVERAGE'] = 'true'
  Rake::Task['test'].execute
end

task default: :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ''

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "xlsx_to_k8s_network_policy #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
