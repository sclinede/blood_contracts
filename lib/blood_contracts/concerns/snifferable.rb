if defined?(Sniffer)
  module BloodContracts::Concerns::Snifferable
    def sniffer_request(http_call)
      return {} unless requested_http?(http_call)
      last_http_session = http_call.meta["last_http_session"].to_a
      last_http_session.map do |session|
        session["request"].to_h.slice("body", "query")
      end
    end

    def sniffer_response(http_call)
      return {} unless requested_http?(http_call)
      last_http_session = http_call.meta["last_http_session"].to_a
      last_http_session.map do |session|
        session["response"].to_h.slice("body", "status")
      end
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
      meta["last_http_session"] = sniffer_buffer.map do |session|
        ::Hashie::Hash[session.to_h].stringify_keys
      end
    end

    def before_call(*)
      super
      enable_sniffer!
    end

    def before_runner(meta:, **kwargs)
      super
      merge_sniffer_buffer!(meta, Sniffer.data)
      disable_sniffer!
    end
  end
end
