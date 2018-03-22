module BloodContracts
  class BaseContract
    extend Dry::Initializer
    option :object, optional: true
    option :method_name, optional: true
    option :action, optional: true, as: :action_proc

    option :meta, default: -> { Hash.new }

    class << self
      def priority(config)
        priorities = {}
        config.each_pair do |priority, rules|
          rules.each { |rule| priorities[rule] ||= priority }
        end
        BloodContracts.config.priorities[to_s.pathize] ||= priorities
      end

      def rules
        @rules ||= Set.new
      end

      def contract_rule(name, &block)
        define_method("_#{name}", block)
        rules << name
      end
    end

    def enable!
      Thread.current[to_s.pathize] = true
    end

    def disable!
      Thread.current[to_s.pathize] = false
    end

    def enabled?
      if Thread.current[to_s.pathize].nil?
        Thread.current[to_s.pathize] = BloodContracts.config.enabled
      end
      !!Thread.current[to_s.pathize]
    end

    def action
      @action ||= action_proc || object.method(method_name)
    end

    def runner
      @runner ||= Runner.new(context: self, suite: to_contract_suite)
    end

    def call(*args, **kwargs)
      return yield unless enabled?
      result = nil
      runner.call(*args, **kwargs) do |meta|
        result = if block_given?
                  yield(meta)
                else
                  action.call(*args, **kwargs)
                end
      end
      result
    end

    def contract
      @contract ||= Hash[
        self.class.rules.map { |name| [name, { check: method("_#{name}") }] }
      ]
    end

    def build_storage(name)
      s = Storage.new(contract_name: name)
      s.input_writer  = method(:input_writer)  if defined? input_writer
      s.output_writer = method(:output_writer) if defined? output_writer
      s.input_serializer  = input_serializer   if defined? input_serializer
      s.output_serializer = output_serializer  if defined? output_serializer
      s.meta_serializer   = meta_serializer    if defined? meta_serializer
      s
    end

    def to_contract_suite(name: self.class.to_s.pathize)
      Suite.new(storage: build_storage(name), contract: contract)
    end
  end
end
