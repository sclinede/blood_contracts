# frozen_string_literal: true

require "anyway_config"

module BloodContracts
  class Config < Anyway::Config
    config_name :contracts
    attr_config store: true,
                sampling: {
                  period: nil,
                  limits_per_tag: {}
                },
                storage: {
                  type: :file, # or :postgres
                  # database_url: ENV["DATABASE_URL"], # when :postgres storage
                  # table_name: "samples",             # when :postgres storage
                },
                enabled: false,
                tags: {},
                debug_file: '.bcontracts_debug'
  end
end
