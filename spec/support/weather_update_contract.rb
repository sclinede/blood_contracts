require "timeout"
require "json"

# rubocop:disable Metrics/MethodLength
# patch service with contract that collects extra data to meta during call
def apply_contract
  return if WeatherService.instance_methods.include?(:weather_update_contract)
  patch = Module.new do
    def weather_update_contract
      @weather_update_contract ||= WeatherUpdateContract.new
    end

    def update(*args)
      weather_update_contract.call(*args) do |meta|
        begin
          super(*args)
        ensure
          meta["raw_response"] = @raw_response
        end
      end
    end

    def load_response(*)
      return super unless weather_update_contract.enabled?
      @raw_response = super
    end
  end
  WeatherService.prepend(patch)
end
# rubocop:enable Metrics/MethodLength

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
    "#{round.response.city.downcase[0..6]}_weather".gsub(/\W/, "_").to_sym
  end

  guarantee :correct_response do |round|
    round.response.respond_to?(:temperature) &&
      round.response.respond_to?(:city) &&
      round.response.respond_to?(:error) &&
      round.response.respond_to?(:success?)
  end

  expect :usual do |round|
    next unless round.response.success? &&
                !round.response.city.to_s.empty? &&
                (-100..100).cover?(round.response.temperature)

    next unless round.response.city.downcase =~ /(london|saint-p)/
    expect(rule_name_from_city(round), tag: :critical_data) { |_| true }
  end

  expect :client_error, tag: :exception do |round|
    next if round.response.success?
    (400..499).cover?(round.response.code.to_i)
  end

  expect :server_error, tag: :exception do |round|
    next if round.response.success?
    (500..599).cover?(round.response.code.to_i)
  end

  expect_error :parsing_error, tag: :exception do |round|
    round.error.keys.include?(JSON::ParserError.to_s)
  end

  expect_error :timeout_error, tag: :exception do |round|
    round.error.keys.include?(Timeout::Error.to_s)
  end

  statistics_guarantee :usual, threshold: "90%"
end
