if defined?(Sniffer)
  class ContractSniffer
    attr_reader :meta
    # attr_reader :sniffer
    def initialize(http_round: nil, meta: nil)
      @meta = http_round&.meta || meta
      # @sniffer = Sniffer.new(logger: nil)
    end

    def request
      requests.last.to_h
    end

    def requests
      return [] unless requested_http?
      last_http_session = meta["last_http_session"].to_a
      last_http_session.map do |session|
        session["request"].to_h.slice("body", "query")
      end
    end

    def response
      responses.last.to_h
    end

    def responses
      return [] unless requested_http?
      last_http_session = meta["last_http_session"].to_a
      last_http_session.map do |session|
        session["response"].to_h.slice("body", "status")
      end
    end

    def requested_http?
      meta.to_h.fetch("requested_http") { false }
    end

    def enable!
      ::Sniffer.config.logger = nil
      ::Sniffer.enable!
      ::Sniffer.clear!
      ::Sniffer.data
    end

    def disable!
      ::Sniffer.clear!
      ::Sniffer.disable!
    end

    def capture!
      sniffer.capture { yield }
      sniffer_buffer = sniffer.data
      requested_api = sniffer_buffer.size.positive?
      meta["requested_http"] = requested_api
      return unless requested_api
      meta["last_http_session"] = sniffer_buffer.map do |session|
        Hashie.stringify_keys_recursively!(session.to_h)
      end
    end

    def merge_buffer_to_meta!
      sniffer_buffer = ::Sniffer.data
      requested_api = sniffer_buffer.size.positive?
      meta["requested_http"] = requested_api
      return unless requested_api
      meta["last_http_session"] = sniffer_buffer.map do |session|
        Hashie.stringify_keys_recursively!(session.to_h)
      end
    end
  end

  module BloodContracts
    module Concerns
      module Snifferable
        def self.included(klass)
          klass.extend ClassMethods
          klass.instance_variable_set(:@sniffers, {})
        end

        module ClassMethods
          def sniffer(http_round = nil, meta: nil, **kwargs)
            http_round ||= kwargs[:http_round]
            input = kwargs.fetch(:input) { http_round.input }
            fetch_sniffer(
              input: input,
              meta: meta
            )
          end

          def fetch_sniffer(input:, meta:)
            @sniffers.fetch(input) do |key|
              @sniffers.store(key, ContractSniffer.new(meta: meta))
            end
          end
        end

        # def around_call(**kwargs)
        #   sniffer_args = kwargs.slice(:input, :output, :meta)
        #   self.class.fetch_sniffer(sniffer_args).capture { super }
        # end

        def before_call(meta:, **kwargs)
          super
          @_sniffer = self.class.sniffer(meta: meta, input: kwargs)
          @_sniffer.enable!
        end

        def before_runner(*)
          super
          @_sniffer.merge_buffer_to_meta!
          @_sniffer.disable!
          @_sniffer = nil
        end
      end
    end
  end
else
  warn "You're attempted to use Snifferable, but Sniffer class is not "\
       "registered yet. Please, install `sniffer` gem."
end
