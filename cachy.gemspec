$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
name = "cachy"
require "#{name}/version"

Gem::Specification.new name, Cachy::VERSION do |s|
  s.summary = "Caching library for projects that have many processes or many caches"
  s.summary = "See which gems depend on your gems"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "https://github.com/grosser/#{s.name}"
  s.files = `git ls-files lib/`.split("\n")
  s.license = "MIT"
  cert = File.expand_path("~/.ssh/gem-private-key-grosser.pem")
  if File.exist?(cert)
    s.signing_key = cert
    s.cert_chain = ["gem-public_cert.pem"]
  end
  s.add_runtime_dependency "mini_memory_store"
end
