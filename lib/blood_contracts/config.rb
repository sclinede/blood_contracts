# frozen_string_literal: true

require "anyway_config"

module BloodContracts
  class Config < Anyway::Config
    # TODO: sync using Postrges or Redis storage
    config_name :contracts
    attr_config store: true,
                enabled: false,
                sampling: {
                  period: nil,
                  limit_per_tag: {}
                },
                storage: {
                  type: :file, # or :postgres
                  # database_url: ENV["DATABASE_URL"], # when :postgres
                  samples_table_name: "blood_samples", # when :postgres
                  config_table_name: "blood_config",   # when :postgres
                },
                tags: {},
                debug_file: ".bcontracts_debug"


    def contract_enabled?(contract_name)

    end
  end
end
