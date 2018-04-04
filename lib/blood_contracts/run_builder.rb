module BloodContracts
  module RunBuilder
    using StringPathize

    def runner
      @runner ||= Runner.new(context: self, suite: to_contract_suite)
    end

    def _contract
      @_contract ||= Hash[
        self.class.rules.map { |name| [name, { check: method("_#{name}") }] }
      ]
    end

    def storage
      return @storage if defined? @storage
      s = Storage.new(contract_name: self.class.to_s.pathize)

      s.input_writer  = method(:input_writer)    if defined? input_writer
      s.input_writer  = method(:request_writer)  if defined? request_writer
      s.output_writer = method(:output_writer)   if defined? output_writer
      s.output_writer = method(:response_writer) if defined? response_writer

      s.input_serializer  = request_serializer if defined? request_serializer
      s.input_serializer  = input_serializer   if defined? input_serializer
      s.output_serializer = output_serializer  if defined? output_serializer
      s.output_serializer = response_serializer if defined? response_serializer

      s.meta_serializer   = meta_serializer if defined? meta_serializer
      @storage = s
    end

    def to_contract_suite
      Suite.new(storage: storage, contract: _contract)
    end
  end
end
