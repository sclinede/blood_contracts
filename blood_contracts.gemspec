
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "blood_contracts/version"

Gem::Specification.new do |spec|
  spec.name          = "blood_contracts"
  spec.version       = BloodContracts::VERSION
  spec.authors       = ["Sergey Dolganov"]
  spec.email         = ["dolganov@evl.ms"]

  spec.summary       = %q{Ruby gem to define and validate behavior of API using contracts.}
  spec.description   = %q{Ruby gem to define and validate behavior of API using contracts.}
  spec.homepage      = "https://github.com/sclinede/blood_contracts"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  # Will be introduced soon
  # spec.bindir        = "exe"
  # spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "dry-initializer", "~> 2.0"

  # Will be removed soon
  spec.add_runtime_dependency "activesupport", ">= 3.1"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
