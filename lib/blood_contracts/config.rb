# frozen_string_literal: true

require "anyway_config"
require "tmpdir"

module BloodContracts
  class Config < Anyway::Config
    config_name :contracts
    attr_config enabled: false,
                statistics: {
                  period: 3600,
                  storage: :memory
                },
                switching: {
                  storage: :memory
                },
                sampling: {
                  period: nil,
                  limit_per_tag: {},
                  storage: :file
                },
                storage: {
                  file: {
                    root: defined?(::Rails) ? ::Rails.root : Dir.tmpdir,
                    samples_folder: "blood_samples"
                  },
                  memory: {},
                  postgres: {
                    # connection: -> { ... },
                    # release_connection: ->(c) { c.finish },
                    # database_url: "",
                    samples_table_name: "blood_samples",
                    config_table_name: "blood_config"
                  },
                  redis: {
                    # connection: -> { ... },
                    # redis_url: "",
                    root_key: "blood_redis"
                  }
                },
                tags: {},
                debug_file: ".blood_debug"

  end
end
