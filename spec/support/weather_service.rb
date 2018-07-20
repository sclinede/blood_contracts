require_relative 'weather_update_contract'
class WeatherService
  extend BloodContracts::Contractable

  contractable WeatherUpdateContract,
               after_call: [:update_contract_postprocess, :update_contract_postprocess2]
  def update(template = :london)
    case template
    when :timeout
      sleep(1)
      raise Timeout::Error
    else
      Response.new(load_response(template))
    end
  end

  private

  def update_contract_postprocess(_input, _output, meta)
    meta["raw_response"] = @raw_response
  end

  def update_contract_postprocess2(_input, _output, meta)
    meta["test"] = 123
  end

  def load_response(name)
    @raw_response =
      File.read(File.join(__dir__, "..", "fixtures/responses/#{name}.json"))
  end

  class Response
    attr_reader :code, :error

    def initialize(raw)
      @data = JSON.parse(raw)
      @code = @data["cod"]
      @error = @data["message"] unless @code == 200
    end

    def temperature
      convert_to_celsius(@data.dig("main", "temp"))
    end

    def city
      @data["name"]
    end

    def success?
      return false unless error.nil?
      !!temperature
    end

    private

    def convert_to_celsius(kelvin)
      return unless kelvin
      kelvin.to_f - 273.15
    end
  end
end
