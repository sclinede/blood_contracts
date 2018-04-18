require "timeout"
require "json"

class WeatherContract < BloodContracts::BaseContract
  def output_writer(round)
    JSON.pretty_generate round.response.instance_variable_get(:@data).to_h
  end

  guarantee :correct_response do |round|
    next(true) if round.error?
    round.response.respond_to?(:temperature) &&
      round.response.respond_to?(:city) &&
      round.response.respond_to?(:error) &&
      round.response.respond_to?(:success?)
  end

  expect :usual do |round|
    next if round.error?
    round.response.success? &&
      !round.response.city.to_s.empty? &&
      (-100..100).cover?(round.response.temperature)
  end

  expect :client_error, tag: :exception do |round|
    next if round.error?
    next if round.response.success?
    (400..499).cover?(round.response.code.to_i)
  end

  expect :server_error, tag: :exception do |round|
    next if round.error?
    next if round.response.success?
    (500..599).cover?(round.response.code.to_i)
  end

  expect :parsing_error, tag: :exception do |round|
    round.error.keys.include?(JSON::ParserError.to_s)
  end

  expect :timeout_error, tag: :exception do |round|
    round.error.keys.include?(Timeout::Error.to_s)
  end

  expect :saint_p_weather, tag: :critical_data, inherit: :usual do |round|
    round.response.city.casecmp("saint-petersburg").zero?
  end

  expect :london_weather, tag: :critical_data, inherit: :usual do |round|
    round.response.city.casecmp("london").zero?
  end

  expect_statistics :usual, threshold: "90%"
end
