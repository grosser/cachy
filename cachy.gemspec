name = "cachy"
require "./lib/#{name}/version"

Gem::Specification.new name, Cachy::VERSION do |s|
  s.summary = "Caching library for projects that have many processes or many caches"
  s.summary = "See which gems depend on your gems"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "https://github.com/grosser/#{name}"
  s.files = `git ls-files lib/`.split("\n")
  s.license = "MIT"
  s.add_runtime_dependency "mini_memory_store"
end
