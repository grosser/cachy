# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{cachy}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Michael Grosser"]
  s.date = %q{2009-09-08}
  s.email = %q{grosser.michael@gmail.com}
  s.extra_rdoc_files = [
    "README.markdown"
  ]
  s.files = [
    "README.markdown",
     "Rakefile",
     "VERSION",
     "cachy.gemspec",
     "lib/cachy.rb",
     "lib/cachy/memcached_wrapper.rb",
     "lib/cachy/moneta_wrapper.rb",
     "lib/cachy/wrapper.rb",
     "spec/cachy/memcached_wrapper_spec.rb",
     "spec/cachy/moneta_wrapper_spec.rb",
     "spec/cachy_spec.rb",
     "spec/spec_helper.rb",
     "spec/test_cache.rb"
  ]
  s.homepage = %q{http://github.com/grosser/cachy}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{Caching library for projects that have many processes or many caches}
  s.test_files = [
    "spec/test_cache.rb",
     "spec/cachy/memcached_wrapper_spec.rb",
     "spec/cachy/moneta_wrapper_spec.rb",
     "spec/spec_helper.rb",
     "spec/cachy_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
