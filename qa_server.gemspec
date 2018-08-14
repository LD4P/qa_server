$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "qa_server/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "qa_server"
  s.version     = QaServer::VERSION
  s.authors     = ["E. Lynette Rayle"]
  s.email       = ["elr37@cornell.edu"]
  s.homepage    = "http://github.com/LD4P/qa_server"
  s.summary     = "Authority Lookup Server"
  s.description = "A rails engine with questioning authority gem installed to serve as an authority search server with normalized results."
  s.license     = 'Apache-2.0'

  s.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  s.executables   = s.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  # Note: rails does not follow sem-ver conventions, it's
  # minor version releases can include breaking changes; see
  # http://guides.rubyonrails.org/maintenance_policy.html
  s.add_dependency 'rails', '~> 5.0'

  # s.add_development_dependency 'sqlite3'
  # s.add_development_dependency 'puma', '~> 3.7'
  # s.add_development_dependency 'sass-rails', '~> 5.0'
  # s.add_development_dependency 'uglifier', '>= 1.3.0'
  # # s.add_dependency 'therubyracer', platforms: :ruby
  # s.add_dependency 'coffee-rails', '~> 4.2'
  # s.add_dependency 'turbolinks', '~> 5'
  # s.add_dependency 'jbuilder', '~> 2.5'
  # # s.add_dependency 'redis', '~> 3.0'
  # # s.add_dependency 'bcrypt', '~> 3.1.7'





  # s.add_development_dependency 'bixby', '~> 1.0.0' # rubocop styleguide
  s.add_development_dependency 'capybara', '~> 2.13'
  s.add_development_dependency 'engine_cart', '~> 2.0'
  s.add_development_dependency 'selenium-webdriver'







  # s.add_development_dependency 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # # s.add_development_dependency 'web-console', '>= 3.3.0'
  # # s.add_development_dependency 'listen', '>= 3.0.5', '< 3.2'
  # # s.add_development_dependency 'spring'
  # # s.add_development_dependency 'spring-watcher-listen', '~> 2.0.0'
  #
  # s.add_dependency 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby] # timezone info

  # Required gems for QA and linked data access
  # s.add_dependency 'qa' # loaded specific branch in Gemfile
  s.add_dependency 'linkeddata'

end
