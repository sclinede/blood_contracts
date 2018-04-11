# frozen_string_literal: true

require "anyway_config"

module BloodContracts
  class Config < Anyway::Config
    config_name :contracts
    attr_config store: true,
                enabled: false,
                sampling: {
                  statistics_period: nil,
                  storage_period: nil,
                  limit_per_tag: {}
                },
                storage: {
                  type: :file, # or :postgres
                  # TODO: add Redis support for config storage
                  # shared_via: :pg or :redis,
                  # redis_url: ENV["REDIS_URL"], # when :redis
                  # redis_connection: -> { ... } # when :redis
                  #
                  # pg_connection: -> { ... }          # when :postgres
                  database_url: ENV["DATABASE_URL"],   # when :postgres
                  samples_table_name: "blood_samples", # when :postgres
                  config_table_name: "blood_config",   # when :postgres
                },
                tags: {},
                debug_file: ".bcontracts_debug"
  end
end
