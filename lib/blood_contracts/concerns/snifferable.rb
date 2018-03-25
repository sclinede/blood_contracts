if defined?(Sniffer)
  module BloodContracts::Concerns::Snifferable
    def sniffer_request(http_call)
      return {} unless requested_http?(http_call)
      last_http_session = http_call.meta["last_http_session"].to_h
      last_http_request = last_http_session.deep_stringify_keys["request"]
      last_http_request.slice("body", "query")
    end

    def sniffer_response(http_call)
      return {} unless requested_http?(http_call)
      last_http_session = http_call.meta["last_http_session"].to_h
      last_http_response = last_http_session.deep_stringify_keys["response"]
      last_http_response.slice("body", "status")
    end

    def requested_http?(http_call)
      http_call.meta.to_h.fetch("requested_http") { false }
    end

    def enable_sniffer!
      Sniffer.config.logger = nil
      Sniffer.enable!
      Sniffer.clear!
      Sniffer.data
    end

    def disable_sniffer!
      Sniffer.clear!
      Sniffer.disable!
    end

    def merge_sniffer_buffer!(meta, sniffer_buffer)
      requested_api = sniffer_buffer.size.positive?
      meta["requested_http"] = requested_api
      return unless requested_api
      last_http_session = sniffer_buffer.last.to_h.deep_stringify_keys
      meta["last_http_session"] = last_http_session
    end

    def before_runner(meta)
      merge_sniffer_buffer!(meta, Sniffer.data)
      disable_sniffer!
    end

    def call(*)
      super do |meta|
        enable_sniffer!
        yield(meta)
      end
    end
  end
end
