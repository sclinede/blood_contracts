class WeatherService
  def update(template = :london)
    case template
    when :timeout
      sleep(1)
      fail Timeout::Error
    else
      Response.new(load_response(template))
    end
  end

  private

  def load_response(name)
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
