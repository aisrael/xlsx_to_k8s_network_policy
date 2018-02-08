# Generated by juwelier
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Juwelier::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: xlsx_to_k8s_network_policy 0.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "xlsx_to_k8s_network_policy".freeze
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Alistair A. Israel".freeze]
  s.date = "2018-02-08"
  s.description = "Generate Kubernetes Network Policy YAML resource definitions from .xlsx Excel spreadsheets".freeze
  s.email = "aisrael@gmail.com".freeze
  s.executables = ["xlsx_to_k8s_network_policy".freeze]
  s.extra_rdoc_files = [
<<<<<<< HEAD
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "bin/xlsx_to_k8s_network_policy",
    "lib/xlsx_to_k8s_network_policy.rb"
=======
    "LICENSE.txt"
  ]
  s.files = [
    "Gemfile",
    "LICENSE.txt",
    "Rakefile",
    "lib/xlsx_to_k8s_network_policy.rb",
    "xlsx_to_k8s_network_policy.gemspec"
>>>>>>> master
  ]
  s.homepage = "http://github.com/aisrael/xlsx_to_k8s_network_policy".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.7.3".freeze
  s.summary = "Generate Kubernetes Network Policy from Excel".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>.freeze, ["~> 5.1.4"])
      s.add_runtime_dependency(%q<roo>.freeze, ["~> 2.7.1"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.16.1"])
      s.add_development_dependency(%q<juwelier>.freeze, ["~> 2.1.0"])
      s.add_development_dependency(%q<rdoc>.freeze, ["~> 6.0.1"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.7"])
      s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.52.1"])
      s.add_development_dependency(%q<shoulda>.freeze, ["~> 3.5.0"])
      s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.15.1"])
    else
      s.add_dependency(%q<activesupport>.freeze, ["~> 5.1.4"])
      s.add_dependency(%q<roo>.freeze, ["~> 2.7.1"])
      s.add_dependency(%q<bundler>.freeze, ["~> 1.16.1"])
      s.add_dependency(%q<juwelier>.freeze, ["~> 2.1.0"])
      s.add_dependency(%q<rdoc>.freeze, ["~> 6.0.1"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.7"])
      s.add_dependency(%q<rubocop>.freeze, ["~> 0.52.1"])
      s.add_dependency(%q<shoulda>.freeze, ["~> 3.5.0"])
      s.add_dependency(%q<simplecov>.freeze, ["~> 0.15.1"])
    end
  else
    s.add_dependency(%q<activesupport>.freeze, ["~> 5.1.4"])
    s.add_dependency(%q<roo>.freeze, ["~> 2.7.1"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.16.1"])
    s.add_dependency(%q<juwelier>.freeze, ["~> 2.1.0"])
    s.add_dependency(%q<rdoc>.freeze, ["~> 6.0.1"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.7"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 0.52.1"])
    s.add_dependency(%q<shoulda>.freeze, ["~> 3.5.0"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.15.1"])
  end
end

