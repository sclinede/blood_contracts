module BloodContracts
  module Samplers
    class Sample
      extend Dry::Initializer

      param :path
      param :contract_name
      option :period, optional: true
      option :round, optional: true

      attr_reader :timestamp
      def initialize(*)
        super
        reset_timestamp!
      end

      def name(tag)
        File.join(path, current_period.to_s, tag.to_s, current_round.to_s)
      end

      def current_period
        period || Time.now.to_i / period_size
      end

      def current_round
        round || timestamp
      end

      private

      def reset_timestamp!
        @timestamp = Time.now.strftime("%Y%m%d%H%M%S%4N")[8..-1]
      end

      def period_size
        BloodContracts.sampling_config[:period] || 1
      end
    end
  end
end
