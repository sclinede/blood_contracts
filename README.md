[adt_wiki]: https://en.wikipedia.org/wiki/Algebraic_data_type
[functional_programming_wiki]: https://en.wikipedia.org/wiki/Functional_programming
[refinement_types_wiki]: https://en.wikipedia.org/wiki/Refinement_type
[ebaymag]: https://ebaymag.com/

# BloodContracts

Simple and agile Ruby data validation tool inspired by refinement types and functional approach

* **Powerful**. [Algebraic Data Type][adt_wiki] guarantees that gem is enough to implement any kind of complex data validation, while [Functional Approach][functional_programming_wiki] gives you full control over validation outcomes
* **Simple**. You could write your first [Refinment Type][refinement_types_wiki] as simple as single Ruby method in single class
* **Brings transparency**. Comes with instrumentation tools, so now you will exactly know how often each type matches in your production
* **Rubyish**. DSL is inspired by Ruby Struct. If you love Ruby way you'd like the BloodContracts types
* **Born in production**. Created on basis of [eBaymag][ebaymag] project, used as a tool to control and monitor data inside API communication

<a href="https://evilmartians.com/?utm_source=blood_contracts&utm_campaign=project_page">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54">
</a>

```ruby
# Example of using for Rubygems API

require 'blood_contracts'
require 'net/http'
require 'json'

module RubygemsAPI
  def self.gem(name)
    Request.and_then(Response).match(name) do |request|
      uri = request.unpack
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.get(uri.request_uri).body
    end
  end

  class Json < BC::Refined
    def match
      # now it's easy to understand why we caught JSON::ParserError
      context[:response] = value.to_s
      context[:parsed] ||= ::JSON.parse(context[:response])
      self
    rescue JSON::ParserError => ex
      context[:exception] = ex # now we could easily playaround with exception and reraise it
      failure(:invalid_json)
    end

    # so the next validation in the pipe will receive parsed response, not unparsed string
    def mapped
      context[:parsed]
    end
  end

  class GemInfo < BC::Refined
    # I chose some data that is interesing for me
    INFO_KEYS = %w(name downloads info authors version homepage_uri source_code_uri)

    def match
      # We have to make sure that result is a hash with appropriate keys
      is_a_project = value.is_a?(Hash) && (INFO_KEYS - value.keys).empty?
      return failure(:reponse_is_not_gem_info) unless is_a_project

      context[:gem_info] = value.slice(*INFO_KEYS)
      self
    end

    def mapped
      context[:gem_info]
    end
  end

  class PlainTextError < BC::Refined
    def match
      context[:response] = value.to_s
      # to avoid multiple parsing of response, we'll try to save it
      context[:parsed] = JSON.parse(context[:response])
      failure(:non_plain_text_response)
    rescue JSON::ParserError
      self
    end

    def mapped
      context[:response]
    end
  end

  class Request < BC::Refined
    ROOT = "https://rubygems.org/api/v1/gems/".freeze

    def match
      context[:name] = String(value)
      context[:uri] = URI.parse("#{File.join(ROOT, context[:name])}.json")
      self
    rescue StandardError => ex
      context[:exception] = ex # now we could easily playaround with exception and reraise it
      failure(:invalid_gem_name_for_request)
    end

    def mapped
      context[:uri]
    end
  end

  # ... compose them...
  Response = PlainTextError.or_a(Json.and_then(GemInfo))
end

# ... and match!
case gem = RubygemsAPI.gem("rack")
when GemInfo
  gem.unpack # show data to user
when PlaintTextError
  {message: gem.unpack, status: 400} # wrap it into json response
else 
  # ...basically it's a case of ContractFailure, we have to improve contract then
  Honeybadger.notify("Unexpected Rubygems API behavior", context: gem.messages)
  {message: "Service is not available at the moment!", status: 500}
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
  # Attach to every BC::Refined ancestor with RubygemsAPI::Response in the name
  cfg.instrument "RubygemsAPI::Response", Contracts::YabedaInstrument.new
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
