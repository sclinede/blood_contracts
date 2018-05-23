module BloodContracts
  module Contracts
    module Toolbox
      using StringPathize

      def self.included(klass)
        klass.prepend Initializer
      end

      module Initializer
        def initialize(*)
          reset_statistics!
          reset_switcher!
          reset_sampler!
          super
          reset_status!
        end
      end

      WRITERS_4_SAMPLER = {
        input_writer: :input_writer=,
        request_writer: :input_writer=,
        request_formatter: :input_writer=,
        output_writer: :output_writer=,
        response_writer: :output_writer=,
        response_formatter: :output_writer=
      }.freeze

      SERIALIZERS_4_SAMPLER = {
        input_serializer: :input_serializer=,
        request_serializer: :input_serializer=,
        output_serializer: :output_serializer=,
        response_serializer: :output_serializer=,
        meta_serializer: :meta_serializer=
      }.freeze

      attr_reader :sampler
      def reset_sampler!
        sampler = Sampler.new(contract_name: self.class.to_s.pathize)

        WRITERS_4_SAMPLER.each do |writer_method, sampler_accessor|
          next unless respond_to?(writer_method)
          sampler.send(sampler_accessor, method(writer_method))
        end

        SERIALIZERS_4_SAMPLER.each do |serializer_method, sampler_accessor|
          next unless respond_to?(serializer_method)
          sampler.send(sampler_accessor, send(serializer_method))
        end

        @sampler = sampler
      end

      attr_reader :status
      def reset_status!
        @status = Status.new(self)
      end

      attr_reader :statistics
      def reset_statistics!
        @statistics = Statistics.new(contract_name: self.class.to_s.pathize)
      end

      attr_reader :switcher
      def reset_switcher!
        @switcher = Switcher.new(contract_name: self.class.to_s.pathize)
      end
    end
  end
end
