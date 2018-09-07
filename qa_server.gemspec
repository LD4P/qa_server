# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'qa_server/version'

Gem::Specification.new do |spec|
  spec.authors       = ["E. Lynette Rayle"]
  spec.email         = ["elr37@cornell.edu"]
  spec.description   = "A rails engine with questioning authority gem installed to serve as an authority search server with normalized results."
  spec.summary       = "Authority Lookup Server"

  spec.homepage      = "http://github.com/LD4P/qa_server"

  spec.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.name          = "qa_server"
  spec.require_paths = ["lib"]
  spec.version       = QaServer::VERSION
  spec.license       = 'Apache-2.0'

  # spec.required_ruby_version = '>= 2.3'

  # Note: rails does not follow sem-ver conventions, it's
  # minor version releases can include breaking changes; see
  # http://guides.rubyonrails.org/maintenance_policy.html
  spec.add_dependency 'rails', '5.1.6' ### TODO: This shouldn't be this restrictive.  Why is it pinned to 5.1.6?

  # Required gems for QA and linked data access
  spec.add_development_dependency 'qa' # loaded specific branch in Gemfile
  spec.add_development_dependency 'linkeddata'

  # Produces dashboard charts on monitor status page
  spec.add_dependency 'chartkick'

  spec.add_development_dependency 'bixby', '~> 1.0.0' # rubocop styleguide
  # spec.add_development_dependency 'capybara', '~> 2.13'
  spec.add_development_dependency 'engine_cart', '~> 2.0'
  spec.add_development_dependency 'rspec-activemodel-mocks', '~> 1.0'
  spec.add_development_dependency 'rspec-its', '~> 1.1'
  spec.add_development_dependency 'rspec-rails', '~> 3.1'
  # spec.add_development_dependency 'selenium-webdriver'
end
