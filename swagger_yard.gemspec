$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "swagger_yard/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = "swagger_yard"
  s.version = SwaggerYard::VERSION
  s.authors = ["chtrinh (Chris Trinh)"]
  s.email = ["chris@synctv.com"]
  s.homepage = "http://www.synctv.com"
  s.summary = "SwaggerYard API doc through YARD"
  s.description = "SwaggerYard API doc gem that uses YARD to parse the docs for a REST rails API"
  s.licenses = ["MIT"]

  s.files = Dir["{app,config,public,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  s.add_runtime_dependency "yard"
  s.add_runtime_dependency "parslet"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rspec-its"
  s.add_development_dependency "apivore"
  s.add_development_dependency "nokogiri"
  s.add_development_dependency "addressable"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "mocha"
  s.add_development_dependency "bourne"
  s.add_development_dependency "standardrb"
end
