module BloodContracts
  module Contracts
    module Toolbox
      using StringPathize

      def self.included(klass)
        klass.prepend Initializer
      end

      module Initializer
        def initialize_contract
          super
          reset_statistics!
          reset_switcher!
          reset_sampler!
          reset_status!
          reset_description!
        end
      end

      PREVIEWERS_4_SAMPLER = {
        input_previewer: :input_previewer=,
        request_previewer: :input_previewer=,
        request_formatter: :input_previewer=,
        output_previewer: :output_previewer=,
        response_previewer: :output_previewer=,
        response_formatter: :output_previewer=
      }.freeze

      SERIALIZERS_4_SAMPLER = {
        input_serializer: :input_serializer=,
        request_serializer: :input_serializer=,
        output_serializer: :output_serializer=,
        response_serializer: :output_serializer=,
        meta_serializer: :meta_serializer=
      }.freeze

      attr_reader :description
      def reset_description!
        @description = Description.call(_contract_hash)
      end

      attr_reader :sampler
      def reset_sampler!
        sampler = Sampler.new(contract_name: self.class.to_s.pathize)

        PREVIEWERS_4_SAMPLER.each do |previewer_method, sampler_accessor|
          next unless respond_to?(previewer_method)
          sampler.send(sampler_accessor, method(previewer_method))
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
