# BloodContracts

Ruby gem to define and validate behavior of API using contract.

Possible use-cases:
- Automated external API status check (shooting with critical requests and validation that behavior meets the contract);
- Automated detection of unexpected external API behavior (Rack::request/response pairs that don't match contract);
- Contract definition assistance tool (generate real-a-like requests and iterate through oddities of your system behavior)

<a href="https://evilmartians.com/">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54"></a>

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

```ruby
# define contract
def contract
  Hash[
    success: {
      check: ->(_input, output) do
        data = output.data
        shipping_cost = data.dig(
          "BkgDetails", "QtdShp", "ShippingCharge"
        )
        output.success? && shipping_cost.present?
      end,
      threshold: 0.98,
    },
    data_missing_error: {
      check: ->(_input, output) do
        output.error_codes.present? &&
        (output.error_codes - ["111"]).empty?
      end,
      limit: 0.01,
    },
    data_invalid_error: {
      check: ->(_input, output) do
        output.error_codes.present? &&
        (output.error_codes - ["4300", "123454"]).empty?
      end,
      limit: 0.01,
    },
    strange_weight: {
      check: ->(input, output) do
        input.weight > 100 && output.error_codes.empty? && !output.success?
      end,
      limit: 0.01,
    }
  ]
end

# define the API input
def generate_data
  DHL::RequestData.new(
    data_source.origin_addresses.sample,
    data_source.destinations.sample,
    data_source.prices.sample,
    data_source.products.sample,
    data_source.weights.sample,
    data_source.dates.sample.days.since.to_date.to_s(:iso8601),
    data_source.accounts.sample,
  ).to_h
end

def data_source
  Hashie::Mash.new(load_fixture("dhl/obfuscated-production-data.yaml"))
end

# initiate contract suite
# with default storage (in tmp/blood_contracts/ folder of the project)
contract_suite = BloodContract::Suite.new(
  contract: contract,
  data_generator: method(:generate_data),
)

# with custom storage backend (e.g. Postgres DB)
conn = PG.connect( dbname: "blood_contracts" )
conn.exec(<<~SQL);
  CREATE TABLE runs (
    created_at timestamp DEFAULT current_timestamp,
    contract_name text,
    rules_matched array text[],
    input text,
    output text
  );
SQL

contract_suite = BloodContract::Suite.new(
  contract: contract,
  data_generator: method(:generate_data),

  storage_backend: ->(contract_name, rules_matched, input, output) do
    conn.exec(<<~SQL, contract_name, rules_matched, input, output)
      INSERT INTO runs (contract_name, rules_matched, input, output) VALUES (?, ?, ?, ?);
    SQL
  end
)

# run validation
runner = BloodContract::Runner.new(
           ->(input) { DHL::Client.call(input) }
           suite: contract_suite,
           time_to_run: 3600, # seconds
           # or
           # iterations: 1000
         ).tap(&:call)

# chech the results
runner.valid? # true if behavior was aligned with contract or false in any other case
runner.run_stats # stats about each contract rule or exceptions occasions during the run

```

## TODO
- Add rake task to run contracts validation
- Add executable to run contracts validation

## Possible Features
- Store the actual code of the contract rules in Storage (gem 'sourcify')
- Store reports in Storage
- Export/import contracts to YAML, JSON....
- Contracts inheritance (already exists using `Hash#merge`?)
- Export `Runner#run_stats` to CSV
- Create simple web app, to read the reports

## Other specific use cases

For Rack request/response validation use: `blood_contracts-rack`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sclinede/blood_contracts. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the BloodContracts project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/sclinede/blood_contracts/blob/master/CODE_OF_CONDUCT.md).
