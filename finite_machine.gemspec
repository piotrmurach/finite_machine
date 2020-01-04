lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "finite_machine/version"

Gem::Specification.new do |spec|
  spec.name          = "finite_machine"
  spec.version       = FiniteMachine::VERSION
  spec.authors       = ["Piotr Murach"]
  spec.email         = ["me@piotrmurach.com"]
  spec.description   = %q{A minimal finite state machine with a straightforward syntax. You can quickly model states, add callbacks and use object-oriented techniques to integrate with ORMs.}
  spec.summary       = %q{A minimal finite state machine with a straightforward syntax.}
  spec.homepage      = "https://piotrmurach.github.io/finite_machine/"
  spec.license       = "MIT"

  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
    spec.metadata["changelog_uri"] = "https://github.com/piotrmurach/finite_machine/blob/master/CHANGELOG.md"
    spec.metadata["documentation_uri"] = "https://www.rubydoc.info/gems/finite_machine"
    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/piotrmurach/finite_machine"
  end

  spec.files         = Dir["lib**/*.rb", "finite_machine.gemspec"]
  spec.files        += Dir["README.md", "CHANGELOG.md", "LICENSE.txt"]
  spec.executables   = []
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 2.0.0"

  spec.add_runtime_dependency "concurrent-ruby", "~> 1.0"

  spec.add_development_dependency "bundler", ">= 1.5"
  spec.add_development_dependency "rspec", "~> 3.1"
  spec.add_development_dependency "rspec-benchmark", "~> 0.4.0"
  spec.add_development_dependency "rake"
end
