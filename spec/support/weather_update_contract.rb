require "timeout"
require "json"

class WeatherUpdateContract < BloodContracts::BaseContract
  def response_formatter(round)
    round.meta["raw_response"]
  end

  def response_serializer
    {
      dump: ->(response) do
        Oj.dump(JSON.pretty_generate(response.instance_variable_get(:@data)))
      end,
      load: ->(dump) do
        WeatherService::Response.new(Oj.load(dump)) rescue nil
      end
    }
  end

  def self.rule_name_from_city(round)
    "#{round.response.city.downcase[0..6]}_weather".gsub(/\W/, "_")
  end

  guarantee "correct_response" do |round|
    round.response.respond_to?(:temperature) &&
      round.response.respond_to?(:city) &&
      round.response.respond_to?(:error) &&
      round.response.respond_to?(:success?)
  end

  expect "usual" do |round|
    next unless round.response.success? &&
                !round.response.city.to_s.empty? &&
                (-100..100).cover?(round.response.temperature)

    # next unless round.response.city.downcase =~ /(london|saint-p)/
    expect(rule_name_from_city(round), tag: "critical_data") do |_|
      expect "cold" do |sub_round|
        sub_round.response.temperature.negative?
      end

      expect "warm" do |sub_round|
        sub_round.response.temperature.positive?
      end

      skip
    end
  end

  expect "error_response", tag: "exception" do |round|
    next if round.response.success?

    expect "client" do |sub_round|
      (400..499).cover?(sub_round.response.code.to_i)
    end

    expect "server" do |sub_round|
      (500..599).cover?(sub_round.response.code.to_i)
    end

    skip
  end

  expect_error :parsing_error, tag: "exception" do |round|
    round.error.keys.include?(JSON::ParserError.to_s)
  end

  expect_error :timeout_error, tag: "exception" do |round|
    round.error.keys.include?(Timeout::Error.to_s)
  end

  statistics_guarantee "usual", threshold: "90%"
end
