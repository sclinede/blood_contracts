require "nanoid"

module BloodContracts
  module Storages
    class BaseBackend
      extend Dry::Initializer
      extend Forwardable

      param :storage
      param :example_name
      option :name, default: -> do
        BloodContracts.run_name || ::Nanoid.generate(size: 10)
      end
      def_delegators :@storage, :input_writer, :output_writer,
                     :input_serializer, :output_serializer, :meta_serializer,
                     :error_serializer

      def init; end

      def disable_contract!(*)
        false
      end

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

      def contract_enabled?(*)
        BloodContracts.config.enabled
      end

      def write(writer, cntxt, round_data)
        writer = cntxt.method(writer) if cntxt && writer.respond_to?(:to_sym)
        writer.call(round_data).encode(
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
        Contracts::Round.new(
          input:  load_sample_chunk(:input, sample_name, **kwargs),
          output: load_sample_chunk(:output, sample_name, **kwargs),
          meta:   load_sample_chunk(:meta, sample_name, **kwargs),
          error:  load_sample_chunk(:error, sample_name, **kwargs)
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

      def suggestion
        raise NotImplementedError
      end

      def unexpected_suggestion
        raise NotImplementedError
      end
    end
  end
end
