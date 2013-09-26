# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/version'

Gem::Specification.new do |spec|
  spec.name          = "prerender_rails"
  spec.version       = PrerenderRails::VERSION
  spec.authors       = ["Todd Hooper"]
  spec.email         = ["thoop3@gmail.com"]
  spec.description   = %q{Prerender your backbone/angular/javascript rendered application on the fly when search engines crawl}
  spec.summary       = %q{Prerender your backbone/angular/javascript rendered application on the fly when search engines crawl}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
