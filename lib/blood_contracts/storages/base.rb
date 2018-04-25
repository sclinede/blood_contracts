require "nanoid"
require_relative "../samplers/sample.rb"
require_relative "../samplers/utils.rb"

module BloodContracts
  module Storages
    class Base
      extend Dry::Initializer
      extend Forwardable

      param :contract_name
      option :sampler, optional: true
      option :statistics, optional: true
      option :session, default: -> do
        BloodContracts.session_name || ::Nanoid.generate(size: 10)
      end
      def_delegators :sampler, :input_writer, :output_writer,
                     :input_serializer, :output_serializer, :meta_serializer,
                     :error_serializer

      def init; end

      def enable_contracts_global!
        raise ArgumentError, <<~MESSAGE
          Global "hot" enable for contracts is not supported.
          Please, use configuration setting or another storage backend.
        MESSAGE
      end

      def disable_contracts_global!
        raise ArgumentError, <<~MESSAGE
          Global "hot" disable for contracts is not supported.
          Please, use configuration setting or another storage backend.
        MESSAGE
      end

      def enable_contract!(*)
        false
      end

      def disable_contract!(*)
        false
      end

      def contract_enabled?(*)
        BloodContracts.config.enabled
      end

      def write(writer, cntxt, round_data)
        writer = cntxt.method(writer) if cntxt && writer.respond_to?(:to_sym)
        writer.call(round_data).to_s.encode(
          "UTF-8", invalid: :replace, undef: :replace, replace: "?"
        )
      end

      def find_sample(_sample_name)
        raise NotImplementedError
      end

      def sample_exists?(_sample_name)
        raise NotImplementedError
      end

      def find_all_samples(_run, _tag, _sample)
        raise NotImplementedError
      end

      def load_sample(sample_name = nil, **kwargs)
        Round.new(
          input:  load_sample_chunk(:input,  sample_name, **kwargs),
          output: load_sample_chunk(:output, sample_name, **kwargs),
          meta:   load_sample_chunk(:meta,   sample_name, **kwargs),
          error:  load_sample_chunk(:error,  sample_name, **kwargs),
          input_preview:  load_sample_preview(:input, sample_name, **kwargs),
          output_preview:  load_sample_preview(:output, sample_name, **kwargs)
        )
      end

      def load_sample_chunk(_dump_type, _sample_name, **_kwargs)
        raise NotImplementedError
      end

      def describe_sample(_tag, _round_data, _context)
        raise NotImplementedError
      end

      def serialize_sample(tag, round_data, context)
        %i(input output meta error).each do |type|
          serialize_sample_chunk(type, tag, round_data, context)
        end
      end

      def serialize_sample_chunk(_type, _tag, _round_data, _context)
        raise NotImplementedError
      end
    end
  end
end
