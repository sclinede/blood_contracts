Gem::Specification.new do |spec|
  spec.name          = "blood_contracts"

  spec.version       = "1.0.0"
  spec.authors       = ["Sergey Dolganov (sclinede)"]
  spec.email         = ["sclinede@evilmartians.com"]

  spec.summary       = " Ruby gem for runtime data validation and monitoring using the contracts approach."
  spec.description   = " Ruby gem for runtime data validation and monitoring using the contracts approach."
  spec.homepage      = "https://github.com/sclinede/blood_contracts"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)

  spec.required_ruby_version = ">= 2.4"

  spec.add_runtime_dependency "blood_contracts-core", "~> 0.4"
  spec.add_runtime_dependency "blood_contracts-ext", "~> 0.1"
  spec.add_runtime_dependency "blood_contracts-instrumentation", "~> 0.1"
end
