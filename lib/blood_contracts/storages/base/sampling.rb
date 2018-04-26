module BloodContracts
  module Storages
    class Base
      class Sampling
        extend Forwardable
        attr_reader :sampler
        def_delegators :sampler, :input_writer, :output_writer,
                       :input_serializer, :output_serializer, :meta_serializer,
                       :error_serializer

        def write(writer, cntxt, round_data)
          writer = cntxt.method(writer) if cntxt && writer.respond_to?(:to_sym)
          writer.call(round_data).to_s.encode(
            "UTF-8", invalid: :replace, undef: :replace, replace: "?"
          )
        end

        def find(_sample_name)
          raise NotImplementedError
        end

        def count(_rule)
          raise NotImplementedError
        end

        def exists?(_sample_name)
          raise NotImplementedError
        end

        def find_all(_run, _tag, _sample)
          raise NotImplementedError
        end

        def delete_all(_path = nil, **_kwargs)
          raise NotImplementedError
        end

        def load(sample_name = nil, **kwargs)
          Round.new(
            input:  load_chunk(:input,  sample_name, **kwargs),
            output: load_chunk(:output, sample_name, **kwargs),
            meta:   load_chunk(:meta,   sample_name, **kwargs),
            error:  load_chunk(:error,  sample_name, **kwargs),
            input_preview:  load_preview(:input, sample_name, **kwargs),
            output_preview:  load_preview(:output, sample_name, **kwargs)
          )
        end

        def load_chunk(_dump_type, _sample_name, **_kwargs)
          raise NotImplementedError
        end

        def describe(_tag, _round_data, _context)
          raise NotImplementedError
        end

        def serialize(tag, round_data, context)
          %i(input output meta error).each do |type|
            serialize_chunk(type, tag, round_data, context)
          end
        end

        def serialize_chunk(_type, _tag, _round_data, _context)
          raise NotImplementedError
        end
      end
    end
  end
end
