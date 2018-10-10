
lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "blood_contracts/version"

Gem::Specification.new do |spec|
  spec.name          = "blood_contracts"

  spec.version       = BloodContracts::VERSION
  spec.authors       = ["Sergey Dolganov"]
  spec.email         = ["dolganov@evl.ms"]

  spec.summary       = "Ruby gem to define and validate behavior of API using contracts."
  spec.description   = "Ruby gem to define and validate behavior of API using contracts."
  spec.homepage      = "https://github.com/sclinede/blood_contracts"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  # Will be introduced soon
  # spec.bindir        = "exe"
  # spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.2.0"

  spec.add_runtime_dependency "dry-initializer", "~> 2.0"
  spec.add_runtime_dependency "ann", "~> 0.2"
  spec.add_runtime_dependency "hashie", "~> 3.0"
  spec.add_runtime_dependency "nanoid", "~> 0.2"
  spec.add_runtime_dependency "anyway_config", "~> 1.1"
  spec.add_runtime_dependency "oj", "~> 3.3"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "sniffer"
  spec.add_development_dependency "pry", "~> 0.9"
  spec.add_development_dependency "pry-doc", "~> 0.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pg", "~> 1.0"
  spec.add_development_dependency "redis", ">= 3.2"
  spec.add_development_dependency "connection_pool", ">= 2.2.0"
  spec.add_development_dependency "dotenv", "~> 2.0"
  spec.add_development_dependency "rubocop", "~> 0.52"
  spec.add_development_dependency "timecop", "~> 0.9"
  spec.add_development_dependency "concurrent-ruby", "~> 1.0"
end
