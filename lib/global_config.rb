module BloodContracts::GlobalConfig
  class << self
    def extended(klass)
      klass.instance_variable_set(:@tags, {})
      klass.apply_config!
    end
  end

  attr_writer :session_name
  attr_reader :session_name, :storage_config, :sampling_config,
              :statistics_config, :switcher_config, :tags

  def config
    @config ||= BloodContracts::Config.new
    yield @config if block_given?
    apply_config!(@config)
    @config
  end

  def apply_config!(config = BloodContracts.config)
    @storage_config = Hashie.symbolize_keys!(config.storage)
    @sampling_config = prepare_tool_config(config.sampling, config)
    @statistics_config = prepare_tool_config(config.statistics, config)
    @switcher_config = prepare_tool_config(config.switching, config)
    reset_sampler!
    reset_switcher!
  end

  def prepare_tool_config(source, config)
    base_config = Hashie.symbolize_keys!(source)
    return base_config if (storage_type = base_config[:storage]).nil?
    base_config.merge(
      storage_type: storage_type,
      storage: Hashie.symbolize_keys!(
        config.storage.fetch(storage_type)
      )
    )
  end
end
