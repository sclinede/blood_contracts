# BloodContracts

Simple and agile Ruby data validation tool inspired by refinement types and functional approach

* **Powerful**. [Algebraic Data Type][adt_wiki] guarantees that gem is enough to implement any kind of complex data validation, while [Functional Approach][functional_programming_wiki] gives you full control over validation outcomes
* **Simple**. You could write your first [Refinment Type][refinement_types_wiki] as simple as single Ruby method in single class
* **Brings transparency**. Comes with instrumentation tools, so now you will exactly know how often each type matches in your production
* **Rubyish**. DSL is inspired by Ruby Struct. If you love Ruby way you'd like the BloodContracts types
* **Born in production**. Created on basis of [eBaymag][ebaymag] project, used as a tool to control and monitor data inside API communication

```ruby
# Write your "types" as simple as...
class Email < ::BC::Refined
  REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

  def match
    return if (context[:email] = value.to_s) =~ REGEX
    failure(:invalid_email)
  end
end

class Phone < ::BC::Refined
  REGEX = /\A(\+7|8)(9|8)\d{9}\z/i

  def match
    return if (context[:phone] = value.to_s) =~ REGEX
    failure(:invalid_phone)
  end
end

# ... compose them...
Login = Email.or_a(Phone)

# ... and match!
case match = Login.match("not-a-login")
when Phone, Email
  match # use as you wish, you exactly know what kind of login you received
when BC::ContractFailure # translate error message
  match.messages # => [:no_matches, :invalid_phone, :invalid_email]
else raise # to make sure you covered all scenarios (Functional Way)
end

# And then in
# config/initializers/contracts.rb

module Contracts
  class YabedaInstrument
    def call(session)
      valid_marker = session.valid? ? "V" : "I"
      result = "[#{valid_marker}] #{session.result_type_name}"
      Yabeda.api_contract_matches.increment(result: result)
    end
  end
end

BloodContracts::Instrumentation.configure do |cfg|
  # Attach to every BC::Refined ancestor with Login in the name
  cfg.instrument "Login", Contracts::YabedaInstrument.new
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'blood_contracts'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install blood_contracts

## Usage

This gem is just facade for the whole data validation and monitoring toolset.

For deeper understanding see [BloodContracts::Core](https://github.com/sclinede/blood_contracts-core), [BloodContracts::Ext](https://github.com/sclinede/blood_contracts-ext) and [BloodContracts::Instrumentation](https://github.com/sclinede/blood_contracts-instrumentation)


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sclinede/blood_contracts. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the BloodContracts project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/sclinede/blood_contracts/blob/master/CODE_OF_CONDUCT.md).
