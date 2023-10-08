# frozen_string_literal: true

require_relative "lib/finite_machine/version"

Gem::Specification.new do |spec|
  spec.name          = "finite_machine"
  spec.version       = FiniteMachine::VERSION
  spec.authors       = ["Piotr Murach"]
  spec.email         = ["piotr@piotrmurach.com"]
  spec.description   = "A minimal finite state machine with a straightforward syntax. You can quickly model states, add callbacks and use object-oriented techniques to integrate with ORMs."
  spec.summary       = "A minimal finite state machine with a straightforward syntax."
  spec.homepage      = "https://piotrmurach.github.io/finite_machine/"
  spec.license       = "MIT"

  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
    spec.metadata["bug_tracker_uri"] = "https://github.com/piotrmurach/finite_machine/issues"
    spec.metadata["changelog_uri"] = "https://github.com/piotrmurach/finite_machine/blob/master/CHANGELOG.md"
    spec.metadata["documentation_uri"] = "https://www.rubydoc.info/gems/finite_machine"
    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["rubygems_mfa_required"] = "true"
    spec.metadata["source_code_uri"] = "https://github.com/piotrmurach/finite_machine"
  end

  spec.files = Dir["lib/**/*"]
  spec.extra_rdoc_files = ["README.md", "CHANGELOG.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 2.0.0"

  spec.add_runtime_dependency "concurrent-ruby", "~> 1.0"
  spec.add_runtime_dependency "sync", "~> 0.5"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 3.0"
end
