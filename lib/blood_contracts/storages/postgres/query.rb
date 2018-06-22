require "erb"
require_relative "query/connection"
require_relative "query/dsl"

module BloodContracts
  module Storages
    class Postgres < Base
      class Query
        include Connection
        extend DSL
        extend Dry::Initializer
        option :contract_name, optional: true
        option :session_name, optional: true
        option :sampling_period_name, optional: true
        option :stats_period_name, optional: true
        option :round_name, optional: true

        def initialize(*)
          super
          pg_loaded?
        end

        def execute(query_name, options = {})
          reset_connection!
          prepare_variables(options)
          connection.exec(sql(query_name))
        ensure
          release_connection_proc.call(connection)
        end

        def contract_enabled(contract_name)
          execute(:is_contract_enabled, contract_name: contract_name)
            .first.to_h["enabled"]
        end

        def samples_count(rule_name)
          execute(:count_samples, rule_name: rule_name).first["count"].to_i
        end

        def delete_all_samples(*args)
          execute(:delete_all_samples, parse_arguments!(args))
        end

        ROUND_CHUNK_ARGS = %i(
          session_name sampling_period_name rule_name round_name chunk_name
        )
        ROUND_ARGS = %i(
          session_name sampling_period_name rule_name round_name
        )

        def_single_row_query :load_sample_chunk,
                             field_name: "dump", args: ROUND_CHUNK_ARGS

        def_single_row_query :load_sample_preview,
                             field_name: "preview", args: ROUND_CHUNK_ARGS

        def_single_row_query :find_sample,
                             field_name: "sample_path",
                             template_name: :find_all_samples, args: ROUND_ARGS

        def_multi_rows_query :find_all_samples,
                             field_name: "sample_path", args: ROUND_ARGS

        private

        def sql(query_name)
          ERB.new(::File.read(file_path(query_name))).result(binding)
        end

        def file_path(query_name)
          ::File.join(__dir__, "templates", "#{query_name}.sql.erb")
        end

        def prepare_variables(options)
          return if options.empty?
          options.each { |k, v| instance_variable_set("@#{k}", v.to_s) }
        end
      end
    end
  end
end
