# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "prerender_rails"
  spec.version       = "0.1.1"
  spec.authors       = ["Todd Hooper"]
  spec.email         = ["todd@collectiveip.com"]
  spec.description   = %q{Rails middleware to prerender your javascript heavy pages on the fly by a phantomjs service}
  spec.summary       = %q{Prerender your backbone/angular/javascript rendered application on the fly when search engines crawl}
  spec.homepage      = "https://github.com/collectiveip/prerender_rails"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'rack', '>= 0'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "webmock"
end
