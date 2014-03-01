# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'finite_machine/version'

Gem::Specification.new do |spec|
  spec.name          = "finite_machine"
  spec.version       = FiniteMachine::VERSION
  spec.authors       = ["Piotr Murach"]
  spec.email         = [""]
  spec.description   = %q{A minimal finite state machine with a straightforward syntax. You can quickly model states, add callbacks and use object-oriented techniques to integrate with ORMs.}
  spec.summary       = %q{A minimal finite state machine with a straightforward syntax.}
  spec.homepage      = "https://github.com/peter-murach/finite_machine"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
