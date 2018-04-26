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
        end

        def contract_enabled(contract_name)
          result = execute(:is_contract_enabled, contract_name: contract_name)
          result.first.to_h["enabled"]
        end

        def load_sample_chunk(*args)
          raise ArgumentError unless args.size.eql?(5)
          options = %i(
            session_name sampling_period_name rule_name round_name chunk_name
          ).zip(args)

          execute(:load_sample_chunk, options).first.to_h.fetch("dump")
        end

        def load_sample_description(*args)
          raise ArgumentError unless args.size.eql?(5)
          options = %i(
            session_name sampling_period_name rule_name round_name chunk_name
          ).zip(args)

          execute(:load_sample_description, options)
            .first.to_h.fetch("description")
        end

        def find_sample(*args)
          raise ArgumentError unless args.size.eql?(4)
          options = %i(
            session_name sampling_period_name rule_name round_name
          ).zip(args)

          execute(:find_all_samples, options).first.to_h["sample_path"]
        end

        def find_all_samples(*args)
          raise ArgumentError unless args.size.eql?(4)
          options = %i(
            session_name sampling_period_name rule_name round_name
          ).zip(args)

          execute(:find_all_samples, options)
            .to_a.map { |row| row["sample_path"] }
        end

        def samples_count(rule_name)
          execute(:count_samples, rule_name: rule_name).first["count"].to_i
        end

        private

        def sql(query_name)
          ERB.new(::File.read(file_path(query_name))).result(binding)
        end

        def file_path(query_name)
          ::File.join(__dir__, "templates", "#{query_name}.sql.erb")
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
