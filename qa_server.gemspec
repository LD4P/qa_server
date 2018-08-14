$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "qa_server/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "qa_server"
  s.version     = QaServer::VERSION
  s.authors     = ["E. Lynette Rayle"]
  s.email       = ["elr37@cornell.edu"]
  s.homepage    = "http://ld4p.org"
  s.summary     = "Authority Lookup Server"
  s.description = "A rails engine with questioning authority gem installed to serve as an authority search server with normalized results."
  s.license     = "Apache"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.2.1"

  s.add_development_dependency "sqlite3"
end
