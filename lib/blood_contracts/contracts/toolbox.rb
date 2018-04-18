module BloodContracts
  module Contracts
    module Toolbox
      using StringPathize

      WRITERS_4_SAMPLER = {
        input_writer: :input_writer=,
        request_writer: :input_writer=,
        output_writer: :output_writer=,
        response_writer: :output_writer=
      }.freeze

      SERIALIZERS_4_SAMPLER = {
        input_serializer: :input_serializer=,
        request_serializer: :input_serializer=,
        output_serializer: :output_serializer=,
        response_serializer: :output_serializer=,
        meta_serializer: :meta_serializer=
      }.freeze

      # rubocop:disable Metrics/MethodLength
      def sampler
        return @sampler if defined? @sampler
        s = Sampler.new(contract_name: self.class.to_s.pathize)

        WRITERS_4_SAMPLER.each do |writer_method, sampler_accessor|
          next unless respond_to?(writer_method)
          s.send(sampler_accessor, method(writer_method))
        end

        SERIALIZERS_4_SAMPLER.each do |serializer_method, sampler_accessor|
          next unless respond_to?(serializer_method)
          s.send(sampler_accessor, serializer_method)
        end

        @sampler = s.tap(&:init)
      end
      # rubocop:enable Metrics/MethodLength

      def statistics
        @statistics ||=
          Statistics.new(contract_name: self.class.to_s.pathize).tap(&:init)
      end

      def switcher
        @switcher ||=
          Switcher.new(contract_name: self.class.to_s.pathize).tap(&:init)
      end
    end
  end
end
