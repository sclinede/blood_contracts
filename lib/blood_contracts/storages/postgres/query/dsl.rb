module BloodContracts
  module Storages
    class Postgres < Base
      class Query
        module DSL
          ROUND_CHUNK_ARGS = %i(
            session_name sampling_period_name rule_name round_name chunk_name
          ).freeze
          ROUND_ARGS = %i(
            session_name sampling_period_name rule_name round_name
          ).freeze

          def self.extended(child)
            child.include(InstanceMethods)
          end

          def def_single_row_query(name, **kwargs)
            template_name = kwargs.fetch(:template_name) { name }

            define_method(name) do |*args|
              send(
                :select_single_row,
                template_name,
                parse_arguments!(args, expected_args: kwargs.fetch(:args)),
                field_name: kwargs.fetch(:field_name)
              )
            end
          end

          def def_multi_rows_query(name, **kwargs)
            template_name = kwargs.fetch(:template_name) { name }

            define_method(name) do |*args|
              send(
                :select_multiple_rows,
                template_name,
                parse_arguments!(args, expected_args: kwargs.fetch(:args)),
                field_name: kwargs.fetch(:field_name)
              )
            end
          end

          module InstanceMethods
            private

            def select_single_row(query_name, query_options, field_name:)
              execute(query_name, query_options).first.to_h.fetch(field_name)
            end

            def select_multiple_rows(query_name, query_options, field_name:)
              execute(query_name, query_options).to_a.map { |r| r[field_name] }
            end

            def parse_arguments!(args, expected_args: ROUND_ARGS)
              raise ArgumentError unless args.size.eql?(expected_args.size)
              expected_args.zip(args)
            end
          end
        end
      end
    end
  end
end
