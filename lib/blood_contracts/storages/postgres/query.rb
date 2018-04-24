require "erb"
require_relative "query/connection"

module BloodContracts
  module Storages
    class Postgres < Base
      class Query
        include Connection
        extend Dry::Initializer
        option :contract_name, optional: true
        option :session_name, optional: true
        option :period_name, optional: true
        option :round_name, optional: true

        class << self
          def build(backend)
            pg_loaded?
            new(
              contract_name: backend.contract_name,
              session_name: backend.session,
              period_name: backend.current_period,
              round_name: backend.current_round
            )
          end
        end

        def execute(query_name, options = {})
          reset_connection!
          prepare_variables(options)
          connection.exec(sql(query_name))
        end

        def contract_enabled(contract_name)
          result = execute(:is_contract_enabled, contract_name: contract_name)
          result.first.to_h["enabled"]
        end

        def load_sample_chunk(*args)
          raise ArgumentError unless args.size.eql?(5)
          options = %i(
            session_name period_name rule_name round_name chunk_name
          ).zip(args)

          execute(:load_sample_chunk, options).first.to_h.fetch("dump")
        end

        def load_sample_preview(*args)
          raise ArgumentError unless args.size.eql?(5)
          options = %i(
            session_name period_name rule_name round_name chunk_name
          ).zip(args)

          execute(:load_sample_preview, options).first.to_h.fetch("preview")
        end

        def find_sample(session_name, period_name, rule_name, round_name)
          execute(
            :find_all_samples,
            session_name: session_name,
            period_name: period_name,
            rule_name: rule_name,
            round_name: round_name
          ).first.to_h["sample_path"]
        end

        def find_all_samples(session_name, period_name, rule_name, round_name)
          execute(
            :find_all_samples,
            session_name: session_name,
            period_name: period_name,
            rule_name: rule_name,
            round_name: round_name
          ).to_a.map { |row| row["sample_path"] }
        end

        def samples_count(rule_name)
          execute(:count_samples, rule_name: rule_name).first["count"].to_i
        end

        private

        def sql(query_name)
          ERB.new(File.read(file_path(query_name))).result(binding)
        end

        def file_path(query_name)
          File.join(__dir__, "templates", "#{query_name}.sql.erb")
        end

        def prepare_variables(options)
          return if options.empty?
          options.each do |k, v|
            instance_variable_set("@#{k}", v)
          end
        end
      end
    end
  end
end
