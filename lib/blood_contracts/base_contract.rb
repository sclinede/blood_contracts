module BloodContracts
  class BaseContract
    extend Dry::Initializer
    option :action

    class << self
      def rules
        @rules ||= Set.new
      end

      def contract_rule(name, &block)
        define_method("__#{name}_rule", block)
        rules << name
      end
    end

    def call(data)
      action.call(data)
    end

    def contract
      @contract ||= Hash[self.class.rules.map do |name, block|
        [name, {check: method("__#{name}_rule")}]
      end]
    end

    def build_storage(name)
      s = Storage.new(contract_name: name)
      s.input_writer  = method(:input_writer)  if defined? input_writer
      s.output_writer = method(:output_writer) if defined? output_writer
      s.input_serializer  = input_serializer   if defined? input_serializer
      s.output_serializer = output_serializer  if defined? output_serializer
      s.meta_serializer   = output_serializer  if defined? meta_serializer
      s
    end

    def to_contract_suite(name: self.class.to_s)
      Suite.new(storage: build_storage(name), contract: contract)
    end
  end
end
