$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
name = "cachy"
require "#{name}/version"

Gem::Specification.new name, Cachy::VERSION do |s|
  s.summary = "Caching library for projects that have many processes or many caches"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "http://github.com/grosser/#{name}"
  s.files = `git ls-files`.split("\n")
  s.license = "MIT"
  s.add_runtime_dependency "mini_memory_store"
end
