BloodContracts.middleware do |chain|
  chain.add ::BloodContracts::Statistics::Middleware
  chain.add ::BloodContracts::Sampler::Middleware
  chain.insert_after :all, ::BloodContracts::Validator::Middleware
end
